import SwiftUI

struct HowToPlayView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                rulesSection
                cheatSheetSection
                Color.clear.frame(height: 8)
            }
            .padding(16)
        }
        .background(KCSTheme.parchment.edgesIgnoringSafeArea(.all))
        .navigationBarTitle("How to Play", displayMode: .inline)
    }

    private var rulesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            ruleRow(number: "1", title: "Read the clues",
                    text: "Each dark clue cell shows a total: top-right for the run to the right, bottom-left for the run going down.")
            ruleRow(number: "2", title: "Fill 1–9",
                    text: "Place digits 1 through 9 in the white cells so each run sums exactly to its clue.")
            ruleRow(number: "3", title: "No repeats",
                    text: "Within any single run, every digit must be unique. The same digit may appear in other runs.")
            ruleRow(number: "4", title: "Solve it",
                    text: "When every run is complete with the correct totals and no duplicates, the puzzle is solved.")
        }
        .padding(16)
        .background(KCSTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(KCSTheme.line, lineWidth: 1))
    }

    private func ruleRow(number: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle().fill(KCSTheme.tealSoft).frame(width: 30, height: 30)
                Text(number).font(.system(size: 15, weight: .bold)).foregroundColor(KCSTheme.teal)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 15, weight: .bold)).foregroundColor(KCSTheme.ink)
                Text(text).font(.system(size: 13, weight: .regular)).foregroundColor(KCSTheme.inkSoft).lineSpacing(2)
            }
        }
    }

    private var cheatSheetSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Digit Combination Cheat Sheet")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(KCSTheme.ink)
            Text("Some sums can only be made one way for a given run length. These \"locked\" combinations are the key to cracking a Kakuro.")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(KCSTheme.inkSoft)
                .lineSpacing(2)

            ForEach(cheatGroups, id: \.length) { group in
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(group.length) cells")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(KCSTheme.teal)
                    ForEach(group.entries, id: \.sum) { entry in
                        HStack(spacing: 10) {
                            Text("\(entry.sum)")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(KCSTheme.ink)
                                .frame(width: 34, alignment: .leading)
                            Rectangle().fill(KCSTheme.line).frame(width: 1, height: 18)
                            Text(entry.combo)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(KCSTheme.slate)
                            Spacer()
                        }
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(KCSTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(KCSTheme.line, lineWidth: 1))
            }
        }
    }

    // Classic unique combinations (only one possible digit set).
    private struct CheatGroup { let length: Int; let entries: [CheatEntry] }
    private struct CheatEntry { let sum: Int; let combo: String }

    private var cheatGroups: [CheatGroup] {
        [
            CheatGroup(length: 2, entries: [
                CheatEntry(sum: 3, combo: "1 + 2"),
                CheatEntry(sum: 4, combo: "1 + 3"),
                CheatEntry(sum: 16, combo: "7 + 9"),
                CheatEntry(sum: 17, combo: "8 + 9"),
            ]),
            CheatGroup(length: 3, entries: [
                CheatEntry(sum: 6, combo: "1 + 2 + 3"),
                CheatEntry(sum: 7, combo: "1 + 2 + 4"),
                CheatEntry(sum: 23, combo: "6 + 8 + 9"),
                CheatEntry(sum: 24, combo: "7 + 8 + 9"),
            ]),
            CheatGroup(length: 4, entries: [
                CheatEntry(sum: 10, combo: "1 + 2 + 3 + 4"),
                CheatEntry(sum: 11, combo: "1 + 2 + 3 + 5"),
                CheatEntry(sum: 29, combo: "5 + 7 + 8 + 9"),
                CheatEntry(sum: 30, combo: "6 + 7 + 8 + 9"),
            ]),
            CheatGroup(length: 5, entries: [
                CheatEntry(sum: 15, combo: "1 + 2 + 3 + 4 + 5"),
                CheatEntry(sum: 16, combo: "1 + 2 + 3 + 4 + 6"),
                CheatEntry(sum: 34, combo: "4 + 6 + 7 + 8 + 9"),
                CheatEntry(sum: 35, combo: "5 + 6 + 7 + 8 + 9"),
            ]),
        ]
    }
}
