import Foundation
import SwiftUI

// MARK: - Persisted progress state

struct PuzzleProgress: Codable {
    var filled: [String: Int] = [:]      // "r_c" -> digit (1...9)
    var notes: [String: [Int]] = [:]     // "r_c" -> candidate digits
    var completed: Bool = false
    var bestTime: Int? = nil             // seconds
    var elapsed: Int = 0                 // last in-progress elapsed seconds
    var hintsUsed: Int = 0

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        filled      = (try? c.decodeIfPresent([String: Int].self,  forKey: .filled))      ?? [:]
        notes       = (try? c.decodeIfPresent([String: [Int]].self, forKey: .notes))      ?? [:]
        completed   = (try? c.decodeIfPresent(Bool.self,            forKey: .completed))  ?? false
        bestTime    = (try? c.decodeIfPresent(Int.self,             forKey: .bestTime))   ?? nil
        elapsed     = (try? c.decodeIfPresent(Int.self,             forKey: .elapsed))    ?? 0
        hintsUsed   = (try? c.decodeIfPresent(Int.self,             forKey: .hintsUsed))  ?? 0
    }
}

struct DailyRecord: Codable {
    var lastCompletedKey: String = ""
    var streak: Int = 0
    var bestStreak: Int = 0
    var completedKeys: [String] = []

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        lastCompletedKey = (try? c.decodeIfPresent(String.self,   forKey: .lastCompletedKey)) ?? ""
        streak           = (try? c.decodeIfPresent(Int.self,      forKey: .streak))           ?? 0
        bestStreak       = (try? c.decodeIfPresent(Int.self,      forKey: .bestStreak))       ?? 0
        completedKeys    = (try? c.decodeIfPresent([String].self, forKey: .completedKeys))    ?? []
    }
}

struct LedgerSettings: Codable {
    var soundOn: Bool = true
    var hapticsOn: Bool = true
    var autoCheck: Bool = false
    var onboardingDone: Bool = false

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        soundOn        = (try? c.decodeIfPresent(Bool.self, forKey: .soundOn))        ?? true
        hapticsOn      = (try? c.decodeIfPresent(Bool.self, forKey: .hapticsOn))      ?? true
        autoCheck      = (try? c.decodeIfPresent(Bool.self, forKey: .autoCheck))      ?? false
        onboardingDone = (try? c.decodeIfPresent(Bool.self, forKey: .onboardingDone)) ?? false
    }
}

// MARK: - Store

final class LedgerStore: ObservableObject {
    static let shared = LedgerStore()

    @Published var settings: LedgerSettings
    @Published var daily: DailyRecord
    @Published private(set) var progressMap: [String: PuzzleProgress]

    private let d = UserDefaults.standard
    private enum Keys {
        static let settings = "kcs.settings"
        static let daily = "kcs.daily"
        static let progress = "kcs.progress"
        static let lastPlayed = "kcs.lastPlayed"
    }

    private init() {
        if let data = d.data(forKey: Keys.settings),
           let s = try? JSONDecoder().decode(LedgerSettings.self, from: data) {
            settings = s
        } else {
            settings = LedgerSettings()
        }
        if let data = d.data(forKey: Keys.daily),
           let r = try? JSONDecoder().decode(DailyRecord.self, from: data) {
            daily = r
        } else {
            daily = DailyRecord()
        }
        if let data = d.data(forKey: Keys.progress),
           let m = try? JSONDecoder().decode([String: PuzzleProgress].self, from: data) {
            progressMap = m
        } else {
            progressMap = [:]
        }
    }

    // MARK: Settings

    func saveSettings() {
        if let data = try? JSONEncoder().encode(settings) {
            d.set(data, forKey: Keys.settings)
        }
    }

    // MARK: Progress

    func progress(for id: String) -> PuzzleProgress {
        progressMap[id] ?? PuzzleProgress()
    }

    func setProgress(_ p: PuzzleProgress, for id: String) {
        progressMap[id] = p
        persistProgress()
    }

    private func persistProgress() {
        if let data = try? JSONEncoder().encode(progressMap) {
            d.set(data, forKey: Keys.progress)
        }
    }

    func completedCount(for difficulty: LedgerDifficulty) -> Int {
        var n = 0
        let key = difficultyKey(difficulty)
        for i in 0..<difficulty.puzzlesPerPack {
            if progressMap["\(key)-\(i)"]?.completed == true { n += 1 }
        }
        return n
    }

    func totalCompleted() -> Int {
        progressMap.values.filter { $0.completed }.count
    }

    func bestTime(for id: String) -> Int? {
        progressMap[id]?.bestTime
    }

    private func difficultyKey(_ d: LedgerDifficulty) -> String {
        switch d {
        case .easy: return "easy"
        case .medium: return "medium"
        case .hard: return "hard"
        case .expert: return "expert"
        }
    }

    // MARK: Last played (continue)

    struct LastPlayed: Codable {
        var difficulty: Int
        var index: Int
    }

    var lastPlayed: LastPlayed? {
        get {
            if let data = d.data(forKey: Keys.lastPlayed),
               let lp = try? JSONDecoder().decode(LastPlayed.self, from: data) {
                return lp
            }
            return nil
        }
        set {
            if let v = newValue, let data = try? JSONEncoder().encode(v) {
                d.set(data, forKey: Keys.lastPlayed)
            } else {
                d.removeObject(forKey: Keys.lastPlayed)
            }
        }
    }

    // MARK: Daily

    func registerDailyCompletion(dayKey: String) {
        guard !daily.completedKeys.contains(dayKey) else { return }
        // Determine streak: if last completed was yesterday relative to this key, increment.
        if daily.lastCompletedKey.isEmpty {
            daily.streak = 1
        } else if isConsecutive(prev: daily.lastCompletedKey, next: dayKey) {
            daily.streak += 1
        } else if daily.lastCompletedKey == dayKey {
            // same day, no change
        } else {
            daily.streak = 1
        }
        daily.lastCompletedKey = dayKey
        daily.completedKeys.append(dayKey)
        daily.bestStreak = max(daily.bestStreak, daily.streak)
        saveDaily()
    }

    func dailyCompleted(dayKey: String) -> Bool {
        daily.completedKeys.contains(dayKey)
    }

    // Recompute streak validity relative to today (a missed day breaks the streak).
    func effectiveStreak(today: String) -> Int {
        if daily.lastCompletedKey.isEmpty { return 0 }
        if daily.lastCompletedKey == today { return daily.streak }
        if isConsecutive(prev: daily.lastCompletedKey, next: today) { return daily.streak }
        return 0
    }

    private func saveDaily() {
        if let data = try? JSONEncoder().encode(daily) {
            d.set(data, forKey: Keys.daily)
        }
    }

    private func isConsecutive(prev: String, next: String) -> Bool {
        guard let pd = dateFrom(key: prev), let nd = dateFrom(key: next) else { return false }
        let cal = Calendar(identifier: .gregorian)
        if let diff = cal.dateComponents([.day], from: pd, to: nd).day {
            return diff == 1
        }
        return false
    }

    private func dateFrom(key: String) -> Date? {
        guard key.count == 8 else { return nil }
        let y = Int(key.prefix(4)) ?? 0
        let mStart = key.index(key.startIndex, offsetBy: 4)
        let mEnd = key.index(key.startIndex, offsetBy: 6)
        let m = Int(key[mStart..<mEnd]) ?? 0
        let day = Int(key.suffix(2)) ?? 0
        var comps = DateComponents()
        comps.year = y; comps.month = m; comps.day = day
        return Calendar(identifier: .gregorian).date(from: comps)
    }

    // MARK: Reset

    func resetAll() {
        progressMap = [:]
        daily = DailyRecord()
        lastPlayed = nil
        d.removeObject(forKey: Keys.progress)
        d.removeObject(forKey: Keys.daily)
        d.removeObject(forKey: Keys.lastPlayed)
        // keep settings as-is (sound/haptics/onboarding) per typical UX
        persistProgress()
        saveDaily()
        objectWillChange.send()
    }
}
