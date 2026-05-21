import SwiftUI
import Combine

final class GameViewModel: ObservableObject {
    let puzzle: LedgerPuzzle
    let isDaily: Bool
    let dayKey: String?

    @Published var filled: [[Int]]              // 0 = empty
    @Published var notes: [[Set<Int>]]
    @Published var selected: (Int, Int)? = nil
    @Published var notesMode = false
    @Published var conflicts: Set<String> = []  // "r_c" cells flagged as conflicting
    @Published var checkedWrong: Set<String> = [] // from "check mistakes"
    @Published var elapsed = 0
    @Published var solved = false
    @Published var hintsUsed = 0
    @Published var showCelebration = false

    let maxHints = 3

    private var undoStack: [[[Int]]] = []
    private var undoNotes: [[[Set<Int>]]] = []
    private var timer: Timer?
    private let store = LedgerStore.shared

    var hintsRemaining: Int { max(0, maxHints - hintsUsed) }

    init(puzzle: LedgerPuzzle, isDaily: Bool = false, dayKey: String? = nil) {
        self.puzzle = puzzle
        self.isDaily = isDaily
        self.dayKey = dayKey
        let size = puzzle.size
        filled = Array(repeating: Array(repeating: 0, count: size), count: size)
        notes = Array(repeating: Array(repeating: Set<Int>(), count: size), count: size)

        loadProgress()
        recomputeConflicts()
        checkSolved(animate: false)
    }

    // MARK: - Progress

    private func loadProgress() {
        let p = store.progress(for: puzzle.id)
        for (k, v) in p.filled {
            if let (r, c) = parseKey(k), inBounds(r, c), puzzle.isEntry(r, c) {
                filled[r][c] = v
            }
        }
        for (k, arr) in p.notes {
            if let (r, c) = parseKey(k), inBounds(r, c), puzzle.isEntry(r, c) {
                notes[r][c] = Set(arr)
            }
        }
        elapsed = p.elapsed
        hintsUsed = p.hintsUsed
        solved = p.completed
    }

    func saveProgress() {
        var p = store.progress(for: puzzle.id)
        var f: [String: Int] = [:]
        var n: [String: [Int]] = [:]
        for r in 0..<puzzle.size {
            for c in 0..<puzzle.size where puzzle.isEntry(r, c) {
                if filled[r][c] != 0 { f["\(r)_\(c)"] = filled[r][c] }
                if !notes[r][c].isEmpty { n["\(r)_\(c)"] = Array(notes[r][c]).sorted() }
            }
        }
        p.filled = f
        p.notes = n
        p.elapsed = elapsed
        p.hintsUsed = hintsUsed
        p.completed = solved
        store.setProgress(p, for: puzzle.id)
    }

    // MARK: - Timer

    func startTimer() {
        guard !solved else { return }
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self, !self.solved else { return }
            self.elapsed += 1
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
        saveProgress()
    }

    // MARK: - Selection & input

    func select(_ r: Int, _ c: Int) {
        guard puzzle.isEntry(r, c) else { return }
        selected = (r, c)
        LCFeedback.tap()
    }

    func enterDigit(_ d: Int) {
        guard let (r, c) = selected, puzzle.isEntry(r, c), !solved else { return }
        pushUndo()
        if notesMode {
            if notes[r][c].contains(d) { notes[r][c].remove(d) }
            else { notes[r][c].insert(d) }
        } else {
            if filled[r][c] == d {
                filled[r][c] = 0
            } else {
                filled[r][c] = d
                notes[r][c].removeAll()
            }
            checkedWrong.remove("\(r)_\(c)")
        }
        LCFeedback.tap()
        recomputeConflicts()
        if store.settings.autoCheck { recomputeCheckMistakes(silent: true) }
        checkSolved(animate: true)
        saveProgress()
    }

    func erase() {
        guard let (r, c) = selected, puzzle.isEntry(r, c), !solved else { return }
        pushUndo()
        filled[r][c] = 0
        notes[r][c].removeAll()
        checkedWrong.remove("\(r)_\(c)")
        LCFeedback.tap()
        recomputeConflicts()
        saveProgress()
    }

    func toggleNotesMode() {
        notesMode.toggle()
        LCFeedback.tap()
    }

    // MARK: - Undo

    private func pushUndo() {
        undoStack.append(filled)
        undoNotes.append(notes)
        if undoStack.count > 80 { undoStack.removeFirst(); undoNotes.removeFirst() }
    }

    var canUndo: Bool { !undoStack.isEmpty }

    func undo() {
        guard let f = undoStack.popLast(), let n = undoNotes.popLast() else { return }
        filled = f
        notes = n
        checkedWrong.removeAll()
        LCFeedback.tap()
        recomputeConflicts()
        checkSolved(animate: false)
        saveProgress()
    }

    // MARK: - Hint (reveal one cell)

    func revealHint() {
        guard hintsRemaining > 0, !solved else { LCFeedback.error(); return }
        // Prefer the selected empty/incorrect cell, else first wrong/empty cell.
        var target: (Int, Int)? = nil
        if let (r, c) = selected, puzzle.isEntry(r, c), filled[r][c] != puzzle.cells[r][c].solution {
            target = (r, c)
        }
        if target == nil {
            outer: for r in 0..<puzzle.size {
                for c in 0..<puzzle.size where puzzle.isEntry(r, c) {
                    if filled[r][c] != puzzle.cells[r][c].solution {
                        target = (r, c); break outer
                    }
                }
            }
        }
        guard let (r, c) = target else { return }
        pushUndo()
        filled[r][c] = puzzle.cells[r][c].solution
        notes[r][c].removeAll()
        checkedWrong.remove("\(r)_\(c)")
        hintsUsed += 1
        selected = (r, c)
        LCFeedback.soft()
        recomputeConflicts()
        checkSolved(animate: true)
        saveProgress()
    }

    // MARK: - Check mistakes

    func checkMistakes() {
        recomputeCheckMistakes(silent: false)
    }

    private func recomputeCheckMistakes(silent: Bool) {
        var wrong = Set<String>()
        for r in 0..<puzzle.size {
            for c in 0..<puzzle.size where puzzle.isEntry(r, c) {
                if filled[r][c] != 0 && filled[r][c] != puzzle.cells[r][c].solution {
                    wrong.insert("\(r)_\(c)")
                }
            }
        }
        checkedWrong = wrong
        if !silent {
            if wrong.isEmpty { LCFeedback.soft() } else { LCFeedback.error() }
        }
    }

    // MARK: - Conflicts (live)

    func recomputeConflicts() {
        var flagged = Set<String>()
        // Across runs
        for run in puzzle.acrossRuns { flagRun(run, &flagged) }
        for run in puzzle.downRuns { flagRun(run, &flagged) }
        conflicts = flagged
    }

    private func flagRun(_ run: (sum: Int, cells: [(Int, Int)]), _ flagged: inout Set<String>) {
        var seen: [Int: [(Int, Int)]] = [:]
        var total = 0
        var allFilled = true
        for (r, c) in run.cells {
            let v = filled[r][c]
            if v == 0 { allFilled = false } else {
                total += v
                seen[v, default: []].append((r, c))
            }
        }
        // duplicate digit
        for (_, coords) in seen where coords.count > 1 {
            for (r, c) in coords { flagged.insert("\(r)_\(c)") }
        }
        // sum overflow, or full-but-wrong
        if total > run.sum || (allFilled && total != run.sum) {
            for (r, c) in run.cells where filled[r][c] != 0 {
                flagged.insert("\(r)_\(c)")
            }
        }
    }

    // MARK: - Solved

    func checkSolved(animate: Bool) {
        for r in 0..<puzzle.size {
            for c in 0..<puzzle.size where puzzle.isEntry(r, c) {
                if filled[r][c] != puzzle.cells[r][c].solution {
                    if solved { solved = false }
                    return
                }
            }
        }
        // all correct
        if !solved {
            solved = true
            stopTimer()
            var p = store.progress(for: puzzle.id)
            p.completed = true
            if let bt = p.bestTime { p.bestTime = min(bt, elapsed) } else { p.bestTime = elapsed }
            p.elapsed = elapsed
            p.hintsUsed = hintsUsed
            // Clear the in-progress filled? Keep filled so the board shows the solution.
            var f: [String: Int] = [:]
            for rr in 0..<puzzle.size {
                for cc in 0..<puzzle.size where puzzle.isEntry(rr, cc) {
                    f["\(rr)_\(cc)"] = filled[rr][cc]
                }
            }
            p.filled = f
            store.setProgress(p, for: puzzle.id)
            if isDaily, let key = dayKey { store.registerDailyCompletion(dayKey: key) }
            LCFeedback.success()
            if animate {
                showCelebration = true
            }
        }
    }

    var bestTime: Int? { store.bestTime(for: puzzle.id) }

    // MARK: - Helpers

    private func parseKey(_ k: String) -> (Int, Int)? {
        let parts = k.split(separator: "_")
        guard parts.count == 2, let r = Int(parts[0]), let c = Int(parts[1]) else { return nil }
        return (r, c)
    }

    private func inBounds(_ r: Int, _ c: Int) -> Bool {
        r >= 0 && r < puzzle.size && c >= 0 && c < puzzle.size
    }

    static func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}
