import SwiftUI

struct PuzzleSelectView: View {
    let difficulty: KakuroDifficulty
    @ObservedObject private var store = KakuroStore.shared

    private var difficultyKey: String {
        switch difficulty {
        case .easy: return "easy"
        case .medium: return "medium"
        case .hard: return "hard"
        case .expert: return "expert"
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                headerCard
                grid
                Color.clear.frame(height: 8)
            }
            .padding(16)
        }
        .background(KCSTheme.parchment.edgesIgnoringSafeArea(.all))
        .navigationBarTitle("\(difficulty.title) Pack", displayMode: .inline)
    }

    private var headerCard: some View {
        let done = store.completedCount(for: difficulty)
        let total = difficulty.puzzlesPerPack
        return VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(difficulty.subtitle).font(.system(size: 14, weight: .semibold)).foregroundColor(KCSTheme.ink)
                    Text("\(done) of \(total) puzzles solved").font(.system(size: 12, weight: .medium)).foregroundColor(KCSTheme.inkSoft)
                }
                Spacer()
                Text("\(Int(total > 0 ? Double(done) / Double(total) * 100 : 0))%")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(KCSTheme.teal)
            }
            ProgressBar(value: total > 0 ? Double(done) / Double(total) : 0).frame(height: 8)
        }
        .padding(16)
        .background(KCSTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(KCSTheme.line, lineWidth: 1))
    }

    private var grid: some View {
        let cols = [GridItem(.adaptive(minimum: 78, maximum: 110), spacing: 12)]
        return LazyVGrid(columns: cols, spacing: 12) {
            ForEach(0..<difficulty.puzzlesPerPack, id: \.self) { i in
                let id = "\(difficultyKey)-\(i)"
                let prog = store.progress(for: id)
                NavigationLink(destination: PuzzleLoader(difficulty: difficulty, index: i)) {
                    PuzzleTile(index: i, completed: prog.completed, bestTime: prog.bestTime,
                               inProgress: !prog.completed && !prog.filled.isEmpty)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

struct PuzzleTile: View {
    let index: Int
    let completed: Bool
    let bestTime: Int?
    let inProgress: Bool

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                if completed {
                    StarIcon(color: KCSTheme.amber).frame(width: 20, height: 20)
                } else {
                    Text("\(index + 1)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(KCSTheme.ink)
                }
            }
            .frame(height: 26)

            if completed, let bt = bestTime {
                Text(GameViewModel.formatTime(bt))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(KCSTheme.teal)
            } else if inProgress {
                Text("In progress")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(KCSTheme.amber)
            } else {
                Text("#\(index + 1)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(KCSTheme.inkSoft)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 68)
        .background(completed ? KCSTheme.amber.opacity(0.12) : KCSTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(completed ? KCSTheme.amber.opacity(0.5) : (inProgress ? KCSTheme.teal.opacity(0.5) : KCSTheme.line), lineWidth: 1)
        )
    }
}

// Generates the puzzle off the main render pass with a tiny loading state if needed.
struct PuzzleLoader: View {
    let difficulty: KakuroDifficulty
    let index: Int
    @State private var puzzle: KakuroPuzzle?

    var body: some View {
        Group {
            if let p = puzzle {
                GameView(puzzle: p, title: "\(difficulty.title) · #\(index + 1)")
                    .onAppear {
                        KakuroStore.shared.lastPlayed = KakuroStore.LastPlayed(difficulty: difficulty.rawValue, index: index)
                    }
            } else {
                ZStack {
                    KCSTheme.parchment.edgesIgnoringSafeArea(.all)
                    VStack(spacing: 14) {
                        GridMarkIcon(color: KCSTheme.teal).frame(width: 44, height: 44)
                        Text("Preparing puzzle…")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(KCSTheme.inkSoft)
                    }
                }
                .onAppear {
                    DispatchQueue.global(qos: .userInitiated).async {
                        let p = KakuroCatalog.shared.puzzle(difficulty: difficulty, index: index)
                        DispatchQueue.main.async { puzzle = p }
                    }
                }
            }
        }
        .navigationBarTitle("\(difficulty.title) · #\(index + 1)", displayMode: .inline)
    }
}
