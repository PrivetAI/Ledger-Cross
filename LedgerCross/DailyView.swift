import SwiftUI

struct DailyView: View {
    @ObservedObject private var store = LedgerStore.shared
    @State private var puzzle: LedgerPuzzle?
    @State private var go = false

    private let today = LedgerCatalog.dayKey(Date())

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                card
                streakStrip
                Color.clear.frame(height: 8)
            }
            .padding(16)
        }
        .background(LCTheme.parchment.edgesIgnoringSafeArea(.all))
        .navigationBarTitle("Daily Challenge", displayMode: .inline)
        .onAppear {
            DispatchQueue.global(qos: .userInitiated).async {
                let p = LedgerCatalog.shared.dailyPuzzle(for: Date())
                DispatchQueue.main.async { puzzle = p }
            }
        }
        .background(
            NavigationLink(
                destination: Group {
                    if let p = puzzle {
                        GameView(puzzle: p, title: "Daily · \(prettyDate())", isDaily: true, dayKey: today)
                    } else { EmptyView() }
                },
                isActive: $go) { EmptyView() }
                .hidden()
        )
    }

    private var card: some View {
        let done = store.dailyCompleted(dayKey: today)
        let diff = LedgerCatalog.shared.dailyDifficulty(for: Date())
        return VStack(spacing: 16) {
            ZStack {
                Circle().fill(LCTheme.amber.opacity(0.16)).frame(width: 96, height: 96)
                FlameIcon(color: LCTheme.amber).frame(width: 50, height: 50)
            }
            Text(prettyDate())
                .font(.system(size: 20, weight: .bold, design: .serif))
                .foregroundColor(LCTheme.ink)
            Text("Today's puzzle · \(diff.title)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(LCTheme.inkSoft)

            if done {
                let prog = store.progress(for: "daily-\(today)")
                HStack(spacing: 8) {
                    CheckIcon(color: LCTheme.teal).frame(width: 18, height: 18)
                    Text(prog.bestTime != nil ? "Completed in \(GameViewModel.formatTime(prog.bestTime!))" : "Completed today")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(LCTheme.teal)
                }
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(LCTheme.tealSoft)
                .clipShape(Capsule())
            }

            Button(action: { go = true }) {
                Text(done ? "Replay Today's Puzzle" : "Play Daily Puzzle")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(puzzle == nil ? LCTheme.slateLight : LCTheme.teal)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(puzzle == nil)
        }
        .padding(22)
        .background(LCTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(LCTheme.line, lineWidth: 1))
    }

    private var streakStrip: some View {
        let streak = store.effectiveStreak(today: today)
        return VStack(spacing: 12) {
            HStack {
                Text("Your Streak").font(.system(size: 16, weight: .bold)).foregroundColor(LCTheme.ink)
                Spacer()
                HStack(spacing: 6) {
                    FlameIcon(color: LCTheme.amber).frame(width: 18, height: 18)
                    Text("\(streak)").font(.system(size: 18, weight: .bold, design: .rounded)).foregroundColor(LCTheme.amber)
                }
            }
            HStack(spacing: 8) {
                ForEach(0..<7, id: \.self) { i in
                    let filled = i < min(streak, 7)
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(filled ? LCTheme.amber.opacity(0.18) : LCTheme.line.opacity(0.4))
                                .frame(width: 30, height: 30)
                            if filled {
                                FlameIcon(color: LCTheme.amber).frame(width: 16, height: 16)
                            }
                        }
                        Text("\(i + 1)")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(LCTheme.inkSoft)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            HStack {
                Text("Best streak: \(store.daily.bestStreak) days")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(LCTheme.inkSoft)
                Spacer()
            }
        }
        .padding(18)
        .background(LCTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(LCTheme.line, lineWidth: 1))
    }

    private func prettyDate() -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US")
        f.dateFormat = "MMMM d, yyyy"
        return f.string(from: Date())
    }
}
