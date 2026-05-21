import SwiftUI

struct LedgerGridView: View {
    @ObservedObject var vm: GameViewModel
    let available: CGSize

    // Grid line thickness (points). The line is simply the ink board background
    // showing through a uniform inset around every cell, so it is identical
    // everywhere and never depends on a cell's state.
    private let line: CGFloat = 1.0

    var body: some View {
        let size = vm.puzzle.size
        let scale = UIScreen.main.scale
        let dim = min(available.width, available.height)
        // Snap each cell to a whole number of device pixels so every cell is the
        // exact same size and the grid is perfectly even.
        let cellPx = max(1, floor(dim * scale / CGFloat(size)))
        let cell = cellPx / scale
        let boardSize = cell * CGFloat(size)

        VStack(spacing: 0) {
            ForEach(0..<size, id: \.self) { r in
                HStack(spacing: 0) {
                    ForEach(0..<size, id: \.self) { c in
                        cellView(r, c, side: cell)
                            .frame(width: cell, height: cell)   // fixed slot — never changes
                            .contentShape(Rectangle())
                            .onTapGesture { vm.select(r, c) }
                    }
                }
            }
        }
        .frame(width: boardSize, height: boardSize)
        .background(LCTheme.ink)                                   // shows through as the grid
        .overlay(Rectangle().stroke(LCTheme.ink, lineWidth: 2.5))  // crisp outer frame
        .frame(width: boardSize, height: boardSize)
    }

    // The visible part of a cell, inset by `line` so the ink background forms a
    // uniform grid line around it. It is centered inside its fixed-size slot, so
    // the slot — and therefore the whole grid — never moves or resizes.
    @ViewBuilder
    private func cellView(_ r: Int, _ c: Int, side: CGFloat) -> some View {
        let model = vm.puzzle.cells[r][c]
        let inner = max(0, side - line)
        Group {
            switch model.kind {
            case .block:
                Rectangle().fill(LCTheme.slate)
            case .clue(let down, let across):
                ClueCellView(down: down, across: across, side: inner)
            case .entry:
                entryContent(r, c, side: inner)
            }
        }
        .frame(width: inner, height: inner)
    }

    @ViewBuilder
    private func entryContent(_ r: Int, _ c: Int, side: CGFloat) -> some View {
        let key = "\(r)_\(c)"
        let isSelected = vm.selected.map { $0 == (r, c) } ?? false
        let inRun = isInSelectedRun(r, c)
        let isConflict = vm.conflicts.contains(key)
        let isWrong = vm.checkedWrong.contains(key)
        let digit = vm.filled[r][c]

        ZStack {
            Rectangle()
                .fill(cellFill(isSelected: isSelected, inRun: inRun, conflict: isConflict, wrong: isWrong))
            if digit != 0 {
                Text("\(digit)")
                    .font(.system(size: side * 0.55, weight: .semibold, design: .rounded))
                    .foregroundColor(digitColor(conflict: isConflict, wrong: isWrong))
            } else if !vm.notes[r][c].isEmpty {
                notesGrid(vm.notes[r][c], side: side)
            }
        }
        .frame(width: side, height: side)
        .overlay(
            // Selection ring drawn INSIDE the cell via strokeBorder — it can never
            // extend past the cell bounds, so selecting never changes any size.
            Group {
                if isSelected {
                    Rectangle().strokeBorder(LCTheme.teal, lineWidth: 2)
                }
            }
        )
    }

    private func cellFill(isSelected: Bool, inRun: Bool, conflict: Bool, wrong: Bool) -> Color {
        if wrong { return LCTheme.redSoft }
        if conflict { return LCTheme.redSoft }
        if isSelected { return LCTheme.tealSoft }
        if inRun { return LCTheme.highlight }
        return LCTheme.paper
    }

    private func digitColor(conflict: Bool, wrong: Bool) -> Color {
        if wrong { return LCTheme.red }
        if conflict { return LCTheme.red }
        return LCTheme.ink
    }

    // Highlight only the contiguous across-run and down-run that contain the
    // selected cell — NOT the whole row/column (a Kakuro run stops at any
    // block/clue cell).
    private func isInSelectedRun(_ r: Int, _ c: Int) -> Bool {
        guard let (sr, sc) = vm.selected else { return false }
        if r == sr {
            let lo = min(c, sc), hi = max(c, sc)
            if (lo...hi).allSatisfy({ vm.puzzle.isEntry(r, $0) }) { return true }
        }
        if c == sc {
            let lo = min(r, sr), hi = max(r, sr)
            if (lo...hi).allSatisfy({ vm.puzzle.isEntry($0, c) }) { return true }
        }
        return false
    }

    @ViewBuilder
    private func notesGrid(_ marks: Set<Int>, side: CGFloat) -> some View {
        VStack(spacing: 0) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<3, id: \.self) { col in
                        let d = row * 3 + col + 1
                        Text(marks.contains(d) ? "\(d)" : " ")
                            .font(.system(size: side * 0.20, weight: .medium))
                            .foregroundColor(LCTheme.teal.opacity(0.85))
                            .frame(width: side / 3, height: side / 3)
                    }
                }
            }
        }
        .frame(width: side, height: side)
    }
}

struct ClueCellView: View {
    let down: Int
    let across: Int
    let side: CGFloat

    var body: some View {
        ZStack {
            LCTheme.slate
            // diagonal divider
            Path { p in
                p.move(to: CGPoint(x: 0, y: 0))
                p.addLine(to: CGPoint(x: side, y: side))
            }
            .stroke(LCTheme.ink.opacity(0.55), lineWidth: 0.9)

            // across (top-right)
            if across > 0 {
                Text("\(across)")
                    .font(.system(size: side * 0.34, weight: .bold, design: .rounded))
                    .foregroundColor(LCTheme.parchment)
                    .frame(width: side, height: side, alignment: .topTrailing)
                    .padding(.trailing, side * 0.10)
                    .padding(.top, side * 0.06)
            }
            // down (bottom-left)
            if down > 0 {
                Text("\(down)")
                    .font(.system(size: side * 0.34, weight: .bold, design: .rounded))
                    .foregroundColor(LCTheme.parchment)
                    .frame(width: side, height: side, alignment: .bottomLeading)
                    .padding(.leading, side * 0.10)
                    .padding(.bottom, side * 0.06)
            }
        }
    }
}
