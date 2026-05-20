import SwiftUI

struct HomeView: View {
    @ObservedObject private var store = KakuroStore.shared
    @State private var goSettings = false
    @State private var goHowTo = false

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                header

                continueCard

                dailyCard

                NavigationLink(destination: PacksView()) {
                    sectionLabel("Difficulty Packs", showChevron: true)
                }
                .buttonStyle(PlainButtonStyle())

                packsGrid

                statsCard

                NavigationLink(destination: HowToPlayView()) {
                    infoTile(title: "How to Play", subtitle: "Rules + digit combo cheat sheet",
                             icon: AnyView(GridMarkIcon(color: KCSTheme.teal)))
                }
                .buttonStyle(PlainButtonStyle())

                Color.clear.frame(height: 12)
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)
        }
        .background(KCSTheme.parchment.edgesIgnoringSafeArea(.all))
        .navigationBarTitle("", displayMode: .inline)
        .navigationBarItems(trailing:
            NavigationLink(destination: SettingsView()) {
                GearIcon(color: KCSTheme.ink).frame(width: 24, height: 24)
            }
        )
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 4) {
            Text("Kakuro Cross Sums")
                .font(.system(size: 28, weight: .bold, design: .serif))
                .foregroundColor(KCSTheme.ink)
            Text("Fill the grid · make every sum")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(KCSTheme.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    // MARK: - Continue

    @ViewBuilder
    private var continueCard: some View {
        if let lp = store.lastPlayed, let diff = KakuroDifficulty(rawValue: lp.difficulty) {
            let puzzle = KakuroCatalog.shared.puzzle(difficulty: diff, index: lp.index)
            let done = store.progress(for: puzzle.id).completed
            NavigationLink(destination: GameView(puzzle: puzzle, title: "\(diff.title) · #\(lp.index + 1)")
                .onAppear { store.lastPlayed = lp }) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14).fill(KCSTheme.teal)
                        ChevronIcon(color: .white).frame(width: 22, height: 22).offset(x: 1)
                    }
                    .frame(width: 52, height: 52)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(done ? "Replay Puzzle" : "Continue Playing")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(KCSTheme.ink)
                        Text("\(diff.title) · Puzzle #\(lp.index + 1)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(KCSTheme.inkSoft)
                    }
                    Spacer()
                }
                .padding(14)
                .background(KCSTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(KCSTheme.line, lineWidth: 1))
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    // MARK: - Daily

    private var dailyCard: some View {
        let today = KakuroCatalog.dayKey(Date())
        let streak = store.effectiveStreak(today: today)
        let done = store.dailyCompleted(dayKey: today)
        return NavigationLink(destination: DailyView()) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14).fill(KCSTheme.amber.opacity(0.16))
                    FlameIcon(color: KCSTheme.amber).frame(width: 30, height: 30)
                }
                .frame(width: 56, height: 56)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("Daily Challenge")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(KCSTheme.ink)
                        if done {
                            CheckIcon(color: KCSTheme.teal).frame(width: 16, height: 16)
                        }
                    }
                    Text(done ? "Completed today · streak \(streak)" : "Streak: \(streak) day\(streak == 1 ? "" : "s")")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(KCSTheme.inkSoft)
                }
                Spacer()
                ChevronIcon(color: KCSTheme.inkSoft).frame(width: 20, height: 20)
            }
            .padding(14)
            .background(KCSTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(KCSTheme.line, lineWidth: 1))
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Packs grid

    private var packsGrid: some View {
        let cols = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
        return LazyVGrid(columns: cols, spacing: 12) {
            ForEach(KakuroDifficulty.allCases, id: \.rawValue) { diff in
                NavigationLink(destination: PuzzleSelectView(difficulty: diff)) {
                    packTile(diff)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    private func packTile(_ diff: KakuroDifficulty) -> some View {
        let done = store.completedCount(for: diff)
        let total = diff.puzzlesPerPack
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(diff.title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(KCSTheme.ink)
                Spacer()
                difficultyDots(diff)
            }
            Text(diff.subtitle)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(KCSTheme.inkSoft)
            ProgressBar(value: total > 0 ? Double(done) / Double(total) : 0)
                .frame(height: 7)
            Text("\(done)/\(total) solved")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(KCSTheme.teal)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KCSTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(KCSTheme.line, lineWidth: 1))
    }

    private func difficultyDots(_ diff: KakuroDifficulty) -> some View {
        HStack(spacing: 3) {
            ForEach(0..<4, id: \.self) { i in
                Circle()
                    .fill(i <= diff.rawValue ? KCSTheme.amber : KCSTheme.line)
                    .frame(width: 6, height: 6)
            }
        }
    }

    // MARK: - Stats

    private var statsCard: some View {
        let total = store.totalCompleted()
        let today = KakuroCatalog.dayKey(Date())
        return HStack(spacing: 0) {
            statBlock(value: "\(total)", label: "Solved")
            divider
            statBlock(value: "\(store.effectiveStreak(today: today))", label: "Day Streak")
            divider
            statBlock(value: "\(store.daily.bestStreak)", label: "Best Streak")
        }
        .padding(.vertical, 16)
        .background(KCSTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(KCSTheme.line, lineWidth: 1))
    }

    private func statBlock(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(KCSTheme.teal)
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(KCSTheme.inkSoft)
        }
        .frame(maxWidth: .infinity)
    }

    private var divider: some View {
        Rectangle().fill(KCSTheme.line).frame(width: 1, height: 34)
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String, showChevron: Bool) -> some View {
        HStack {
            Text(text)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(KCSTheme.ink)
            Spacer()
            if showChevron {
                Text("All")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(KCSTheme.teal)
                ChevronIcon(color: KCSTheme.teal).frame(width: 16, height: 16)
            }
        }
        .padding(.top, 4)
    }

    private func infoTile(title: String, subtitle: String, icon: AnyView) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(KCSTheme.tealSoft)
                icon.frame(width: 26, height: 26)
            }
            .frame(width: 48, height: 48)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 16, weight: .bold)).foregroundColor(KCSTheme.ink)
                Text(subtitle).font(.system(size: 12, weight: .medium)).foregroundColor(KCSTheme.inkSoft)
            }
            Spacer()
            ChevronIcon(color: KCSTheme.inkSoft).frame(width: 20, height: 20)
        }
        .padding(14)
        .background(KCSTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(KCSTheme.line, lineWidth: 1))
    }
}

struct ProgressBar: View {
    let value: Double // 0...1
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(KCSTheme.line.opacity(0.5))
                Capsule().fill(KCSTheme.teal)
                    .frame(width: max(0, min(1, value)) * geo.size.width)
            }
        }
    }
}

struct PacksView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(KakuroDifficulty.allCases, id: \.rawValue) { diff in
                    NavigationLink(destination: PuzzleSelectView(difficulty: diff)) {
                        PackRow(difficulty: diff)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(16)
        }
        .background(KCSTheme.parchment.edgesIgnoringSafeArea(.all))
        .navigationBarTitle("Difficulty Packs", displayMode: .inline)
    }
}

struct PackRow: View {
    let difficulty: KakuroDifficulty
    @ObservedObject private var store = KakuroStore.shared
    var body: some View {
        let done = store.completedCount(for: difficulty)
        let total = difficulty.puzzlesPerPack
        return HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14).fill(KCSTheme.tealSoft)
                Text("\(difficulty.gridSize)")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(KCSTheme.teal)
            }
            .frame(width: 58, height: 58)
            VStack(alignment: .leading, spacing: 5) {
                Text(difficulty.title).font(.system(size: 18, weight: .bold)).foregroundColor(KCSTheme.ink)
                Text(difficulty.subtitle).font(.system(size: 13, weight: .medium)).foregroundColor(KCSTheme.inkSoft)
                ProgressBar(value: total > 0 ? Double(done) / Double(total) : 0).frame(height: 7).frame(maxWidth: 180)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(done)/\(total)").font(.system(size: 15, weight: .bold, design: .rounded)).foregroundColor(KCSTheme.teal)
                ChevronIcon(color: KCSTheme.inkSoft).frame(width: 18, height: 18)
            }
        }
        .padding(14)
        .background(KCSTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(KCSTheme.line, lineWidth: 1))
    }
}
