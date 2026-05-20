import SwiftUI

struct KakuroCrossSumsLoadingScreen: View {
    @State private var pulse = false

    var body: some View {
        ZStack {
            KCSTheme.parchment.edgesIgnoringSafeArea(.all)
            VStack(spacing: 28) {
                ZStack {
                    // Mini ledger grid mark
                    RoundedRectangle(cornerRadius: 16)
                        .fill(KCSTheme.paper)
                        .frame(width: 108, height: 108)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(KCSTheme.ink, lineWidth: 3)
                        )
                    VStack(spacing: 0) {
                        ForEach(0..<3) { r in
                            HStack(spacing: 0) {
                                ForEach(0..<3) { c in
                                    cell(r, c)
                                }
                            }
                        }
                    }
                    .frame(width: 108, height: 108)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .scaleEffect(pulse ? 1.05 : 0.95)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: pulse)

                Text("Kakuro Cross Sums")
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .foregroundColor(KCSTheme.ink)
                Text("Loading puzzles…")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(KCSTheme.inkSoft)
            }
        }
        .onAppear { pulse = true }
    }

    @ViewBuilder
    private func cell(_ r: Int, _ c: Int) -> some View {
        let isClue = (r == 0 || c == 0)
        ZStack {
            Rectangle()
                .fill(isClue ? KCSTheme.slate : KCSTheme.paper)
            Rectangle().stroke(KCSTheme.ink.opacity(0.4), lineWidth: 1)
            if !isClue {
                Text("\(r * c + 1)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(KCSTheme.teal)
            }
        }
        .frame(width: 36, height: 36)
    }
}
