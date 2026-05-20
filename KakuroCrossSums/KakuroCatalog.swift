import Foundation

// Lazily generates and caches the deterministic puzzle catalog.
// 120 puzzles total: 30 per difficulty across 4 difficulties, plus date-seeded daily.
final class KakuroCatalog {
    static let shared = KakuroCatalog()

    private var packCache: [String: KakuroPuzzle] = [:]   // key "diff-index"
    private var dailyCache: [String: KakuroPuzzle] = [:]
    private let queue = DispatchQueue(label: "kcs.catalog", attributes: .concurrent)

    private init() {}

    // Stable per-puzzle seed via SplitMix64-style integer mixing of difficulty + index.
    private func seed(difficulty: KakuroDifficulty, index: Int) -> UInt64 {
        var z = UInt64(0xA5A5_5A5A_1234_5678)
        z = z &+ UInt64(difficulty.rawValue + 1) &* 0x9E37_79B9_7F4A_7C15
        z = z &+ UInt64(index + 1) &* 0xC2B2_AE3D_27D4_EB4F
        z = (z ^ (z >> 29)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 32))
        return z
    }

    func puzzle(difficulty: KakuroDifficulty, index: Int) -> KakuroPuzzle {
        let id = "\(difficultyKey(difficulty))-\(index)"
        var existing: KakuroPuzzle?
        queue.sync { existing = packCache[id] }
        if let p = existing { return p }

        let p = KakuroGenerator.makePuzzle(id: id, difficulty: difficulty, seed: seed(difficulty: difficulty, index: index))
        queue.async(flags: .barrier) { self.packCache[id] = p }
        return p
    }

    // Generate the whole pack (used on background warm-up).
    func warmPack(_ difficulty: KakuroDifficulty) {
        for i in 0..<difficulty.puzzlesPerPack {
            _ = puzzle(difficulty: difficulty, index: i)
        }
    }

    private func difficultyKey(_ d: KakuroDifficulty) -> String {
        switch d {
        case .easy: return "easy"
        case .medium: return "medium"
        case .hard: return "hard"
        case .expert: return "expert"
        }
    }

    // MARK: - Daily

    func dailyDifficulty(for date: Date) -> KakuroDifficulty {
        let key = Self.dayKey(date)
        // Deterministically pick difficulty from the day key digits.
        var z: UInt64 = 0
        for ch in key.unicodeScalars { z = z &+ UInt64(ch.value) &* 0x9E37_79B9_7F4A_7C15 }
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        let pick = Int(z % 3) // Daily uses Easy/Medium/Hard for fair daily play
        return KakuroDifficulty(rawValue: pick) ?? .easy
    }

    func dailyPuzzle(for date: Date) -> KakuroPuzzle {
        let key = Self.dayKey(date)
        var cached: KakuroPuzzle?
        queue.sync { cached = dailyCache[key] }
        if let c = cached { return c }

        let diff = dailyDifficulty(for: date)
        var z: UInt64 = 0xDA11_0000_0000_0000
        for ch in key.unicodeScalars { z = z &+ UInt64(ch.value) &* 0xC2B2_AE3D_27D4_EB4F }
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        z ^= (z >> 31)
        let p = KakuroGenerator.makePuzzle(id: "daily-\(key)", difficulty: diff, seed: z)
        queue.async(flags: .barrier) { self.dailyCache[key] = p }
        return p
    }

    static func dayKey(_ date: Date) -> String {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone.current
        let comps = cal.dateComponents([.year, .month, .day], from: date)
        let y = comps.year ?? 2026
        let m = comps.month ?? 1
        let d = comps.day ?? 1
        return String(format: "%04d%02d%02d", y, m, d)
    }
}
