import SwiftUI

struct LedgerCrossLoadingScreen: View {
    @State private var pulse = false

    var body: some View {
        ZStack {
            LCTheme.parchment.edgesIgnoringSafeArea(.all)
            VStack(spacing: 28) {
                ZStack {
                    // Mini ledger grid mark
                    RoundedRectangle(cornerRadius: 16)
                        .fill(LCTheme.paper)
                        .frame(width: 108, height: 108)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(LCTheme.ink, lineWidth: 3)
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

                Text("Ledger Cross")
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .foregroundColor(LCTheme.ink)
                Text("Loading puzzles…")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(LCTheme.inkSoft)
            }
        }
        .onAppear { pulse = true }
    }

    @ViewBuilder
    private func cell(_ r: Int, _ c: Int) -> some View {
        let isClue = (r == 0 || c == 0)
        ZStack {
            Rectangle()
                .fill(isClue ? LCTheme.slate : LCTheme.paper)
            Rectangle().stroke(LCTheme.ink.opacity(0.4), lineWidth: 1)
            if !isClue {
                Text("\(r * c + 1)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(LCTheme.teal)
            }
        }
        .frame(width: 36, height: 36)
    }
}
