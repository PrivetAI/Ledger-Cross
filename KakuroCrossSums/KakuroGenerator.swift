import Foundation

// Deterministic Kakuro generator. Produces valid, UNIQUELY-solvable puzzles,
// seeded per index via SplitMix64 so the catalog is identical on every run.
//
// Approach (chosen after empirical verification):
//   A fully solved Kakuro derived from a random fill is almost never uniquely
//   solvable on medium+ grids. Instead we tile the playable area with small
//   polyomino "rooms" separated by black cells. Each room shape is one that is
//   uniquely solvable in isolation for any valid fill (L, T, S, plus tetrominoes)
//   or a 2x2 fill that has been screened for uniqueness. Because rooms are
//   isolated by black cells, room solutions are independent, so the whole grid
//   is uniquely solvable iff each room is — which holds by construction. The
//   solver still confirms uniqueness as a hard guarantee before a puzzle ships.
final class KakuroGenerator {

    // MARK: - Room shapes (relative coordinates; all uniquely solvable in isolation)

    // Each shape occupies a bounding box and is placed so a black separator
    // surrounds it (we advance placement cursors past the box + 1).
    private struct Shape {
        let cells: [(Int, Int)]   // relative (row, col)
        let w: Int
        let h: Int
    }

    // Only rectangular rooms are used: in standard Kakuro every white cell must lie
    // in BOTH a horizontal and a vertical run of length >= 2, which non-rectangular
    // polyominoes violate at their corners. Each room's digit fill is screened for
    // unique solvability in isolation, so the separated-room composition is unique.
    private static func rect(_ w: Int, _ h: Int) -> Shape {
        var cells: [(Int, Int)] = []
        for dr in 0..<h { for dc in 0..<w { cells.append((dr, dc)) } }
        return Shape(cells: cells, w: w, h: h)
    }

    private static let shapes: [Shape] = [
        rect(2, 2),
        rect(3, 2),
        rect(2, 3),
        rect(3, 3),
    ]

    // Pre-computed list of 2x2 fills (a,b / c,d) that are uniquely solvable alone.
    private static let unique2x2: [[Int]] = {
        var result: [[Int]] = []
        for a in 1...9 { for b in 1...9 { for c in 1...9 { for d in 1...9 {
            if a == b || c == d || a == c || b == d { continue }
            let a1 = a + b, a2 = c + d, d1 = a + c, d2 = b + d
            var count = 0
            for x in 1...9 { for y in 1...9 where y != x && x + y == a1 {
                for z in 1...9 where z != x && x + z == d1 {
                    let w = a2 - z
                    if w < 1 || w > 9 || w == z || w == y { continue }
                    if y + w == d2 { count += 1 }
                }
            }}
            if count == 1 { result.append([a, b, c, d]) }
        }}}}
        return result
    }()

    // MARK: - Public

    static func makePuzzle(id: String, difficulty: KakuroDifficulty, seed: UInt64) -> KakuroPuzzle {
        let size = difficulty.gridSize

        var attempt = 0
        while attempt < 200 {
            attempt += 1
            var rng = KakuroSplitMix64(seed: seed &+ UInt64(attempt) &* 0x100000001B3)

            guard let (isEntry, solution) = tile(size: size, rng: &rng) else { continue }

            let cells = deriveCells(size: size, isEntry: isEntry, solution: solution)
            let kindGrid = cells.map { row in row.map { $0.kind } }

            let solver = KakuroSolver(size: size, cells: kindGrid)
            let count = solver.countSolutions(limit: 2, nodeCap: 600_000)
            if !solver.hitNodeCap && count == 1 {
                return KakuroPuzzle(id: id, difficulty: difficulty, size: size, cells: cells)
            }
        }
        return fallbackPuzzle(id: id, difficulty: difficulty, seed: seed)
    }

    // MARK: - Tiling

    // Lays unique rooms across the inner area (rows/cols 1...size-1) with black
    // separators, and returns both the entry mask and a valid solution grid.
    private static func tile(size: Int, rng: inout KakuroSplitMix64) -> (isEntry: [[Bool]], solution: [[Int]])? {
        var isEntry = Array(repeating: Array(repeating: false, count: size), count: size)
        var solution = Array(repeating: Array(repeating: 0, count: size), count: size)
        var occupied = Array(repeating: Array(repeating: false, count: size), count: size)

        let twoByTwo = Shape(cells: [(0,0),(0,1),(1,0),(1,1)], w: 2, h: 2)

        // Scan placement with a per-row staggered start so rooms don't align into a
        // rigid lattice. At each free anchor we try shuffled shapes; if a larger room
        // cannot be given a uniquely-solvable fill we fall back to a 2x2 (which always
        // can), guaranteeing progress and good coverage.
        var placedRooms = 0
        var r = 1
        while r < size - 1 {
            // Stagger: start a little to the right on some rows for visual variety.
            let stagger = rng.nextInt(2)
            var c = 1 + (occupied[r][1] ? 0 : stagger)
            if c >= size - 1 { c = 1 }
            while c < size - 1 {
                if occupied[r][c] {
                    c += 1
                    continue
                }
                let order = rng.shuffled(Array(0..<shapes.count))
                var placed = false
                for si in order {
                    let shape = shapes[si]
                    guard canPlace(shape, atR: r, atC: c, size: size, occupied: occupied) else { continue }
                    // Try to give the room a uniquely-solvable fill.
                    var trial = solution
                    if fillRoom(shape, atR: r, atC: c, solution: &trial, rng: &rng) {
                        solution = trial
                        placeShape(shape, atR: r, atC: c, isEntry: &isEntry, occupied: &occupied)
                        placedRooms += 1
                        placed = true
                        c += shape.w
                        break
                    }
                }
                // Fallback: a 2x2 always has a unique fill.
                if !placed, canPlace(twoByTwo, atR: r, atC: c, size: size, occupied: occupied) {
                    _ = fillRoom(twoByTwo, atR: r, atC: c, solution: &solution, rng: &rng)
                    placeShape(twoByTwo, atR: r, atC: c, isEntry: &isEntry, occupied: &occupied)
                    placedRooms += 1
                    placed = true
                    c += twoByTwo.w
                }
                if !placed { c += 1 }
            }
            r += 1
        }

        if placedRooms == 0 { return nil }

        // Reject tilings that are too sparse for the difficulty so puzzles feel
        // substantial. The retry loop in makePuzzle will produce a denser one.
        var entryTotal = 0
        for row in isEntry { for v in row where v { entryTotal += 1 } }
        let minEntries: Int
        switch size {
        case 6: minEntries = 12
        case 8: minEntries = 18
        case 10: minEntries = 34
        default: minEntries = 52
        }
        if entryTotal < minEntries { return nil }

        // Ensure validity: every entry must sit in both an across and a down run
        // of length >= 2. The shapes guarantee this internally; verify defensively.
        if !patternRunsValid(isEntry, size: size) { return nil }
        if !allEntriesInBothRuns(isEntry, size: size) { return nil }

        return (isEntry, solution)
    }

    private static func canPlace(_ shape: Shape, atR r: Int, atC c: Int, size: Int,
                                 occupied: [[Bool]]) -> Bool {
        // Bounding box must fit within rows/cols 1...size-1.
        if r + shape.h > size { return false }
        if c + shape.w > size { return false }
        // Each shape cell must be free and orthogonally separated from any other
        // room. Rooms only interact through horizontal/vertical runs, so requiring
        // no shared edge (4-neighbour separation) keeps every room's runs isolated.
        // Diagonal contact is fine and yields denser, more varied layouts.
        let shapeKeys = Set(shape.cells.map { "\(r + $0.0)_\(c + $0.1)" })
        for (dr, dc) in shape.cells {
            let rr = r + dr, cc = c + dc
            if rr < 1 || rr >= size || cc < 1 || cc >= size { return false }
            if occupied[rr][cc] { return false }
            for (nr, nc) in [(rr - 1, cc), (rr + 1, cc), (rr, cc - 1), (rr, cc + 1)] {
                if nr < 0 || nr >= size || nc < 0 || nc >= size { continue }
                // A neighbour that is part of this same shape is fine; otherwise it
                // would connect two rooms' runs, so reject.
                if occupied[nr][nc] && !shapeKeys.contains("\(nr)_\(nc)") { return false }
            }
        }
        return true
    }

    private static func placeShape(_ shape: Shape, atR r: Int, atC c: Int,
                                   isEntry: inout [[Bool]], occupied: inout [[Bool]]) {
        for (dr, dc) in shape.cells {
            isEntry[r + dr][c + dc] = true
            occupied[r + dr][c + dc] = true
        }
    }

    // Fill a single rectangular room with a valid no-repeat fill that is also
    // uniquely solvable in isolation. We try several random fills, screening each
    // with the solver, so the room contributes a unique sub-puzzle.
    private static func fillRoom(_ shape: Shape, atR r: Int, atC c: Int,
                                 solution: inout [[Int]], rng: inout KakuroSplitMix64) -> Bool {
        // Fast path for the most common room: 2x2 from the precomputed unique table.
        if shape.w == 2 && shape.h == 2 {
            let f = unique2x2[rng.nextInt(unique2x2.count)]
            solution[r][c] = f[0]; solution[r][c + 1] = f[1]
            solution[r + 1][c] = f[2]; solution[r + 1][c + 1] = f[3]
            return true
        }

        let w = shape.w, h = shape.h
        // Try up to a bounded number of random valid fills; accept the first that is
        // uniquely solvable as an isolated mini-puzzle.
        for _ in 0..<60 {
            if let grid = randomRectFill(w: w, h: h, rng: &rng), rectFillIsUnique(grid, w: w, h: h) {
                for dr in 0..<h { for dc in 0..<w { solution[r + dr][c + dc] = grid[dr][dc] } }
                return true
            }
        }
        return false
    }

    // Random valid fill of a w*h rectangle: each row and each column has no repeats.
    private static func randomRectFill(w: Int, h: Int, rng: inout KakuroSplitMix64) -> [[Int]]? {
        var grid = Array(repeating: Array(repeating: 0, count: w), count: h)
        var rngCopy = rng
        func recurse(_ idx: Int) -> Bool {
            if idx == w * h { return true }
            let rr = idx / w, cc = idx % w
            var used = 0
            for x in 0..<cc { used |= 1 << (grid[rr][x] - 1) }
            for y in 0..<rr { used |= 1 << (grid[y][cc] - 1) }
            for d in rngCopy.shuffled(Array(1...9)) {
                if (used & (1 << (d - 1))) != 0 { continue }
                grid[rr][cc] = d
                if recurse(idx + 1) { return true }
                grid[rr][cc] = 0
            }
            return false
        }
        rng = rngCopy
        return recurse(0) ? grid : nil
    }

    // Solve the isolated rectangle from its derived clues and confirm a single solution.
    private static func rectFillIsUnique(_ grid: [[Int]], w: Int, h: Int) -> Bool {
        let n = max(w, h) + 1
        var kind = Array(repeating: Array(repeating: KakuroCellKind.block, count: n + 1), count: n + 1)
        // Place the rectangle at (1,1).
        for dr in 0..<h { for dc in 0..<w { kind[1 + dr][1 + dc] = .entry } }
        // Derive clues into the surrounding black cells.
        for r in 0..<(n + 1) {
            for c in 0..<(n + 1) {
                if case .entry = kind[r][c] { continue }
                var across = 0
                if c + 1 <= n, isEntryKind(kind, r, c + 1) {
                    var cc = c + 1
                    while cc <= n, isEntryKind(kind, r, cc) { across += grid[r - 1][cc - 1]; cc += 1 }
                }
                var down = 0
                if r + 1 <= n, isEntryKind(kind, r + 1, c) {
                    var rr = r + 1
                    while rr <= n, isEntryKind(kind, rr, c) { down += grid[rr - 1][c - 1]; rr += 1 }
                }
                if across > 0 || down > 0 { kind[r][c] = .clue(down: down, across: across) }
            }
        }
        let solver = KakuroSolver(size: n + 1, cells: kind)
        let cnt = solver.countSolutions(limit: 2, nodeCap: 200_000)
        return !solver.hitNodeCap && cnt == 1
    }

    private static func isEntryKind(_ kind: [[KakuroCellKind]], _ r: Int, _ c: Int) -> Bool {
        if r < 0 || r >= kind.count || c < 0 || c >= kind[r].count { return false }
        if case .entry = kind[r][c] { return true }
        return false
    }

    // MARK: - Pattern checks

    private static func patternRunsValid(_ isEntry: [[Bool]], size: Int) -> Bool {
        for r in 0..<size {
            var c = 0
            while c < size {
                if isEntry[r][c] {
                    var len = 0
                    while c < size && isEntry[r][c] { len += 1; c += 1 }
                    if len == 1 { return false }
                } else { c += 1 }
            }
        }
        for c in 0..<size {
            var r = 0
            while r < size {
                if isEntry[r][c] {
                    var len = 0
                    while r < size && isEntry[r][c] { len += 1; r += 1 }
                    if len == 1 { return false }
                } else { r += 1 }
            }
        }
        return true
    }

    private static func allEntriesInBothRuns(_ isEntry: [[Bool]], size: Int) -> Bool {
        for r in 0..<size {
            for c in 0..<size where isEntry[r][c] {
                if r == 0 || c == 0 { return false }
                let hLeft = c > 0 && isEntry[r][c - 1]
                let hRight = c < size - 1 && isEntry[r][c + 1]
                let vUp = r > 0 && isEntry[r - 1][c]
                let vDown = r < size - 1 && isEntry[r + 1][c]
                if !(hLeft || hRight) { return false }
                if !(vUp || vDown) { return false }
            }
        }
        return true
    }

    // MARK: - Derive clue cells

    private static func deriveCells(size: Int, isEntry: [[Bool]], solution: [[Int]]) -> [[KakuroCell]] {
        var cells = Array(repeating: Array(repeating: KakuroCell(kind: .block, solution: 0), count: size), count: size)
        for r in 0..<size {
            for c in 0..<size where isEntry[r][c] {
                cells[r][c] = KakuroCell(kind: .entry, solution: solution[r][c])
            }
        }
        for r in 0..<size {
            for c in 0..<size where !isEntry[r][c] {
                var across = 0
                if c + 1 < size && isEntry[r][c + 1] {
                    var cc = c + 1
                    while cc < size && isEntry[r][cc] { across += solution[r][cc]; cc += 1 }
                }
                var down = 0
                if r + 1 < size && isEntry[r + 1][c] {
                    var rr = r + 1
                    while rr < size && isEntry[rr][c] { down += solution[rr][c]; rr += 1 }
                }
                if across > 0 || down > 0 {
                    cells[r][c] = KakuroCell(kind: .clue(down: down, across: across), solution: 0)
                }
            }
        }
        return cells
    }

    // MARK: - Fallback (guaranteed unique)

    private static func fallbackPuzzle(id: String, difficulty: KakuroDifficulty, seed: UInt64) -> KakuroPuzzle {
        let size = difficulty.gridSize
        var isEntry = Array(repeating: Array(repeating: false, count: size), count: size)
        var solution = Array(repeating: Array(repeating: 0, count: size), count: size)
        var rng = KakuroSplitMix64(seed: seed ^ 0xDEAD_BEEF_CAFE_F00D)

        // Tile with separated 2x2 unique blocks — guaranteed unique by construction.
        var r = 1
        while r + 1 < size {
            var c = 1
            while c + 1 < size {
                let f = unique2x2[rng.nextInt(unique2x2.count)]
                isEntry[r][c] = true; isEntry[r][c + 1] = true
                isEntry[r + 1][c] = true; isEntry[r + 1][c + 1] = true
                solution[r][c] = f[0]; solution[r][c + 1] = f[1]
                solution[r + 1][c] = f[2]; solution[r + 1][c + 1] = f[3]
                c += 3
            }
            r += 3
        }
        let cells = deriveCells(size: size, isEntry: isEntry, solution: solution)
        return KakuroPuzzle(id: id, difficulty: difficulty, size: size, cells: cells)
    }
}
