import SwiftUI

struct OnboardingView: View {
    let onFinish: () -> Void
    @State private var step = 0

    private let steps = 4

    var body: some View {
        ZStack {
            KCSTheme.parchment.edgesIgnoringSafeArea(.all)
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button(action: onFinish) {
                        Text("Skip")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(KCSTheme.inkSoft)
                    }
                }
                .padding(.horizontal, 20).padding(.top, 16)

                Spacer()

                content

                Spacer()

                HStack(spacing: 8) {
                    ForEach(0..<steps, id: \.self) { i in
                        Capsule()
                            .fill(i == step ? KCSTheme.teal : KCSTheme.line)
                            .frame(width: i == step ? 22 : 8, height: 8)
                            .animation(.easeInOut(duration: 0.2), value: step)
                    }
                }
                .padding(.bottom, 18)

                Button(action: {
                    if step < steps - 1 {
                        withAnimation { step += 1 }
                        KCSFeedback.tap()
                    } else {
                        onFinish()
                    }
                }) {
                    Text(step < steps - 1 ? "Next" : "Start Playing")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(KCSTheme.teal)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 24).padding(.bottom, 24)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case 0:
            stepView(
                illustration: AnyView(ClueCellsIllustration()),
                title: "Clue Cells",
                body: "Dark cells hold the clues. The number in the top-right is the total for the run to its right. The number in the bottom-left is the total for the run going down."
            )
        case 1:
            stepView(
                illustration: AnyView(FillRuleIllustration()),
                title: "Fill the Runs",
                body: "Type digits 1–9 into the white cells so each horizontal and vertical run adds up exactly to its clue total."
            )
        case 2:
            stepView(
                illustration: AnyView(NoRepeatIllustration()),
                title: "No Repeats",
                body: "A digit can never repeat within the same run. Duplicates and wrong sums are highlighted in red as you play."
            )
        default:
            stepView(
                illustration: AnyView(NotesIllustration()),
                title: "Use Notes",
                body: "Stuck? Switch on Notes to pencil in small candidate digits, tap Check to find mistakes, or spend a Hint to reveal a cell."
            )
        }
    }

    private func stepView(illustration: AnyView, title: String, body: String) -> some View {
        VStack(spacing: 26) {
            illustration
                .frame(width: 180, height: 180)
            VStack(spacing: 12) {
                Text(title)
                    .font(.system(size: 26, weight: .bold, design: .serif))
                    .foregroundColor(KCSTheme.ink)
                Text(body)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(KCSTheme.inkSoft)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 30)
            }
        }
    }
}

// MARK: - Illustrations (custom, built from grid cells)

private struct MiniCell: View {
    enum Kind { case clue(across: Int, down: Int); case entry(Int); case empty; case note([Int]) }
    let kind: Kind
    var highlight: Color? = nil
    var side: CGFloat = 44

    var body: some View {
        ZStack {
            switch kind {
            case .clue(let a, let d):
                ClueCellView(down: d, across: a, side: side)
            case .entry(let v):
                Rectangle().fill(highlight ?? KCSTheme.paper)
                Text("\(v)").font(.system(size: side * 0.5, weight: .semibold, design: .rounded))
                    .foregroundColor(highlight == KCSTheme.redSoft ? KCSTheme.red : KCSTheme.ink)
            case .empty:
                Rectangle().fill(highlight ?? KCSTheme.paper)
            case .note(let marks):
                Rectangle().fill(KCSTheme.paper)
                VStack(spacing: 0) {
                    ForEach(0..<3, id: \.self) { r in
                        HStack(spacing: 0) {
                            ForEach(0..<3, id: \.self) { c in
                                let d = r * 3 + c + 1
                                Text(marks.contains(d) ? "\(d)" : " ")
                                    .font(.system(size: side * 0.18, weight: .medium))
                                    .foregroundColor(KCSTheme.teal)
                                    .frame(width: side / 3, height: side / 3)
                            }
                        }
                    }
                }
            }
        }
        .frame(width: side, height: side)
        .overlay(Rectangle().stroke(KCSTheme.ink.opacity(0.8), lineWidth: 0.8))
    }
}

private struct ClueCellsIllustration: View {
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                MiniCell(kind: .clue(across: 16, down: 0))
                MiniCell(kind: .clue(across: 0, down: 0))
            }
            HStack(spacing: 0) {
                MiniCell(kind: .clue(across: 0, down: 11))
                MiniCell(kind: .empty)
            }
        }
        .background(KCSTheme.ink)
        .overlay(Rectangle().stroke(KCSTheme.ink, lineWidth: 2))
    }
}

private struct FillRuleIllustration: View {
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                MiniCell(kind: .clue(across: 0, down: 0))
                MiniCell(kind: .clue(across: 9, down: 0))
                MiniCell(kind: .clue(across: 0, down: 0))
            }
            HStack(spacing: 0) {
                MiniCell(kind: .clue(across: 0, down: 0))
                MiniCell(kind: .entry(4), highlight: KCSTheme.tealSoft)
                MiniCell(kind: .entry(5), highlight: KCSTheme.tealSoft)
            }
        }
        .background(KCSTheme.ink)
        .overlay(Rectangle().stroke(KCSTheme.ink, lineWidth: 2))
    }
}

private struct NoRepeatIllustration: View {
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                MiniCell(kind: .clue(across: 6, down: 0))
                MiniCell(kind: .entry(3), highlight: KCSTheme.redSoft)
                MiniCell(kind: .entry(3), highlight: KCSTheme.redSoft)
            }
        }
        .background(KCSTheme.ink)
        .overlay(Rectangle().stroke(KCSTheme.ink, lineWidth: 2))
    }
}

private struct NotesIllustration: View {
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                MiniCell(kind: .note([1, 3, 7]))
                MiniCell(kind: .note([2, 4, 9]))
            }
        }
        .background(KCSTheme.ink)
        .overlay(Rectangle().stroke(KCSTheme.ink, lineWidth: 2))
    }
}
