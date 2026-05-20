import Foundation

// MARK: - Difficulty

enum KakuroDifficulty: Int, CaseIterable, Codable {
    case easy = 0
    case medium = 1
    case hard = 2
    case expert = 3

    var title: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        case .expert: return "Expert"
        }
    }

    // Includes the leading clue rows/columns. Inner playable area is size-1.
    var gridSize: Int {
        switch self {
        case .easy: return 6
        case .medium: return 8
        case .hard: return 10
        case .expert: return 12
        }
    }

    var puzzlesPerPack: Int { 30 }

    var subtitle: String {
        switch self {
        case .easy: return "6 × 6 grids"
        case .medium: return "8 × 8 grids"
        case .hard: return "10 × 10 grids"
        case .expert: return "12 × 12 grids"
        }
    }
}

// MARK: - Cell

enum KakuroCellKind: Equatable {
    case block                       // pure black cell, no clues
    case clue(down: Int, across: Int) // black clue cell; 0 means no clue in that direction
    case entry                       // white fillable cell
}

struct KakuroCell: Equatable {
    var kind: KakuroCellKind
    var solution: Int   // 0 for non-entry cells; 1...9 for entry cells
}

// MARK: - Puzzle

// A fully solved & verified Kakuro puzzle.
struct KakuroPuzzle: Equatable {
    let id: String          // stable id, e.g. "easy-3" or "daily-20260520"
    let difficulty: KakuroDifficulty
    let size: Int           // total grid dimension (size x size)
    var cells: [[KakuroCell]]

    func isEntry(_ r: Int, _ c: Int) -> Bool {
        if case .entry = cells[r][c].kind { return true }
        return false
    }

    var entryCount: Int {
        var n = 0
        for row in cells { for cell in row { if cell.kind == .entry { n += 1 } } }
        return n
    }

    // All horizontal runs as arrays of (r,c) coordinates with their across-sum.
    var acrossRuns: [(sum: Int, cells: [(Int, Int)])] {
        var runs: [(sum: Int, cells: [(Int, Int)])] = []
        for r in 0..<size {
            for c in 0..<size {
                if case .clue(_, let across) = cells[r][c].kind, across > 0 {
                    var coords: [(Int, Int)] = []
                    var cc = c + 1
                    while cc < size, isEntry(r, cc) {
                        coords.append((r, cc))
                        cc += 1
                    }
                    if !coords.isEmpty { runs.append((across, coords)) }
                }
            }
        }
        return runs
    }

    var downRuns: [(sum: Int, cells: [(Int, Int)])] {
        var runs: [(sum: Int, cells: [(Int, Int)])] = []
        for r in 0..<size {
            for c in 0..<size {
                if case .clue(let down, _) = cells[r][c].kind, down > 0 {
                    var coords: [(Int, Int)] = []
                    var rr = r + 1
                    while rr < size, isEntry(rr, c) {
                        coords.append((rr, c))
                        rr += 1
                    }
                    if !coords.isEmpty { runs.append((down, coords)) }
                }
            }
        }
        return runs
    }
}
