import Foundation

// MARK: - Digit combination tables

// Standard Kakuro combination helpers operating on 9-bit masks (bit d-1 set => digit d available).
enum KakuroCombos {
    static let full: Int = 0b1_1111_1111 // digits 1...9

    static func mask(for digit: Int) -> Int { 1 << (digit - 1) }

    static func contains(_ mask: Int, _ digit: Int) -> Bool {
        (mask & (1 << (digit - 1))) != 0
    }

    static func count(_ mask: Int) -> Int {
        var m = mask, n = 0
        while m != 0 { n += m & 1; m >>= 1 }
        return n
    }

    // Returns the union of all digit masks that can appear in a run of given length
    // summing to `sum`, given each digit is unique and from 1...9.
    // Cached for speed.
    private static var allowedCache: [Int: Int] = {
        var cache: [Int: Int] = [:]
        for length in 1...9 {
            for sum in 1...45 {
                cache[key(length, sum)] = computeAllowed(length: length, sum: sum)
            }
        }
        return cache
    }()

    private static func key(_ length: Int, _ sum: Int) -> Int { length * 100 + sum }

    static func allowedDigits(length: Int, sum: Int) -> Int {
        guard length >= 1, length <= 9, sum >= 1, sum <= 45 else { return 0 }
        return allowedCache[key(length, sum)] ?? 0
    }

    private static func computeAllowed(length: Int, sum: Int) -> Int {
        var union = 0
        func recurse(start: Int, remaining: Int, target: Int, used: Int) {
            if remaining == 0 {
                if target == 0 { union |= used }
                return
            }
            var d = start
            while d <= 9 {
                if d <= target {
                    recurse(start: d + 1, remaining: remaining - 1, target: target - d, used: used | mask(for: d))
                }
                d += 1
            }
        }
        recurse(start: 1, remaining: length, target: sum, used: 0)
        return union
    }
}

// MARK: - Solver

// Counts solutions, stopping early at `limit`. Used both to solve and to test uniqueness.
final class KakuroSolver {
    private let size: Int
    private var cells: [[KakuroCellKind]]

    // Run metadata.
    private struct Run {
        var sum: Int
        var cellIndices: [Int]   // flat indices into the entry-cell list
    }

    private var entryCoords: [(Int, Int)] = []
    private var coordToEntry: [Int: Int] = [:]   // r*size+c -> entry index
    private var acrossRunOfCell: [Int] = []      // entry index -> across run index (-1 none)
    private var downRunOfCell: [Int] = []        // entry index -> down run index (-1 none)
    private var runs: [Run] = []

    private var values: [Int] = []   // current digit per entry (0 = empty)
    private var rowMaskUsed: [Int] = [] // per-run used-digit mask

    init(size: Int, cells: [[KakuroCellKind]]) {
        self.size = size
        self.cells = cells
        buildMetadata()
    }

    private func buildMetadata() {
        // Index entry cells.
        for r in 0..<size {
            for c in 0..<size {
                if cells[r][c] == .entry {
                    coordToEntry[r * size + c] = entryCoords.count
                    entryCoords.append((r, c))
                }
            }
        }
        let n = entryCoords.count
        acrossRunOfCell = Array(repeating: -1, count: n)
        downRunOfCell = Array(repeating: -1, count: n)
        values = Array(repeating: 0, count: n)

        // Build across runs.
        for r in 0..<size {
            for c in 0..<size {
                if case .clue(_, let across) = cells[r][c], across > 0 {
                    var coords: [Int] = []
                    var cc = c + 1
                    while cc < size, cells[r][cc] == .entry {
                        if let e = coordToEntry[r * size + cc] { coords.append(e) }
                        cc += 1
                    }
                    if !coords.isEmpty {
                        let idx = runs.count
                        runs.append(Run(sum: across, cellIndices: coords))
                        for e in coords { acrossRunOfCell[e] = idx }
                    }
                }
                if case .clue(let down, _) = cells[r][c], down > 0 {
                    var coords: [Int] = []
                    var rr = r + 1
                    while rr < size, cells[rr][c] == .entry {
                        if let e = coordToEntry[rr * size + c] { coords.append(e) }
                        rr += 1
                    }
                    if !coords.isEmpty {
                        let idx = runs.count
                        runs.append(Run(sum: down, cellIndices: coords))
                        for e in coords { downRunOfCell[e] = idx }
                    }
                }
            }
        }
        rowMaskUsed = Array(repeating: 0, count: runs.count)
    }

    // For a cell, candidate digits given current run constraints.
    private func candidates(for entry: Int) -> Int {
        var allowed = KakuroCombos.full
        let ar = acrossRunOfCell[entry]
        let dr = downRunOfCell[entry]
        if ar >= 0 {
            let run = runs[ar]
            let remainingSum = run.sum - currentSum(of: run)
            let remainingLen = run.cellIndices.filter { values[$0] == 0 }.count
            allowed &= KakuroCombos.allowedDigits(length: remainingLen, sum: remainingSum)
            allowed &= ~rowMaskUsed[ar]
        }
        if dr >= 0 {
            let run = runs[dr]
            let remainingSum = run.sum - currentSum(of: run)
            let remainingLen = run.cellIndices.filter { values[$0] == 0 }.count
            allowed &= KakuroCombos.allowedDigits(length: remainingLen, sum: remainingSum)
            allowed &= ~rowMaskUsed[dr]
        }
        return allowed
    }

    private func currentSum(of run: Run) -> Int {
        var s = 0
        for e in run.cellIndices { s += values[e] }
        return s
    }

    // Choose the empty cell with fewest candidates (MRV heuristic).
    private func selectCell() -> Int? {
        var best = -1
        var bestCount = 10
        for e in 0..<values.count where values[e] == 0 {
            let cand = candidates(for: e)
            let cnt = KakuroCombos.count(cand)
            if cnt == 0 { return e } // dead end forces backtrack quickly
            if cnt < bestCount {
                bestCount = cnt
                best = e
                if cnt == 1 { break }
            }
        }
        return best == -1 ? nil : best
    }

    private var solutionCount = 0
    private var limit = 2
    private var firstSolution: [Int]?
    private var nodeBudget = Int.max
    private(set) var hitNodeCap = false

    // Returns the number of solutions found (capped at `limit`).
    // `nodeCap` bounds the search; if exceeded, `hitNodeCap` is set and the search
    // stops early (the returned count is then unreliable and callers should reject).
    func countSolutions(limit: Int = 2, nodeCap: Int = Int.max) -> Int {
        self.limit = limit
        self.nodeBudget = nodeCap
        self.hitNodeCap = false
        solutionCount = 0
        firstSolution = nil
        for i in 0..<values.count { values[i] = 0 }
        for i in 0..<rowMaskUsed.count { rowMaskUsed[i] = 0 }
        backtrack()
        return solutionCount
    }

    // Returns the unique solution if exactly one exists, else nil.
    func solve() -> [(Int, Int, Int)]? {
        let count = countSolutions(limit: 1 + 1) // need to know if >1
        guard count == 1, let sol = firstSolution else { return nil }
        var result: [(Int, Int, Int)] = []
        for (e, v) in sol.enumerated() {
            let (r, c) = entryCoords[e]
            result.append((r, c, v))
        }
        return result
    }

    private func backtrack() {
        if solutionCount >= limit { return }
        if hitNodeCap { return }
        nodeBudget -= 1
        if nodeBudget <= 0 { hitNodeCap = true; return }
        guard let cell = selectCell() else {
            // All filled. Validate run sums (should hold by construction, but verify).
            for run in runs {
                if currentSum(of: run) != run.sum { return }
            }
            solutionCount += 1
            if firstSolution == nil { firstSolution = values }
            return
        }
        let cand = candidates(for: cell)
        if cand == 0 { return }
        let ar = acrossRunOfCell[cell]
        let dr = downRunOfCell[cell]
        var d = 1
        while d <= 9 {
            if KakuroCombos.contains(cand, d) {
                values[cell] = d
                if ar >= 0 { rowMaskUsed[ar] |= KakuroCombos.mask(for: d) }
                if dr >= 0 { rowMaskUsed[dr] |= KakuroCombos.mask(for: d) }

                backtrack()

                values[cell] = 0
                if ar >= 0 { rowMaskUsed[ar] &= ~KakuroCombos.mask(for: d) }
                if dr >= 0 { rowMaskUsed[dr] &= ~KakuroCombos.mask(for: d) }
                if solutionCount >= limit { return }
            }
            d += 1
        }
    }
}
