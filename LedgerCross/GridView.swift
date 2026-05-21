import SwiftUI

struct LedgerGridView: View {
    @ObservedObject var vm: GameViewModel
    let available: CGSize

    var body: some View {
        let size = vm.puzzle.size
        let scale = UIScreen.main.scale
        let dim = min(available.width, available.height)
        // Snap the cell to a whole number of device pixels so every cell is the
        // exact same width and every grid line renders identically — avoids the
        // occasional uneven/blurry lines caused by fractional cell sizes.
        let cellPx = max(1, floor(dim * scale / CGFloat(size)))
        let cell = cellPx / scale
        let boardSize = cell * CGFloat(size)

        VStack(spacing: 0) {
            ForEach(0..<size, id: \.self) { r in
                HStack(spacing: 0) {
                    ForEach(0..<size, id: \.self) { c in
                        cellView(r, c, side: cell)
                    }
                }
            }
        }
        .frame(width: boardSize, height: boardSize)
        .background(LCTheme.paper)
        // A single uniform grid drawn on top of all fills — no doubled per-cell
        // strokes, so interior lines are even everywhere.
        .overlay(gridLines(size: size, cell: cell))
        .overlay(selectedBorder(size: size, cell: cell))
        .overlay(Rectangle().stroke(LCTheme.ink, lineWidth: 2.5))
        .frame(width: boardSize, height: boardSize)
    }

    @ViewBuilder
    private func cellView(_ r: Int, _ c: Int, side: CGFloat) -> some View {
        let model = vm.puzzle.cells[r][c]
        switch model.kind {
        case .block:
            Rectangle()
                .fill(LCTheme.slate)
                .frame(width: side, height: side)
        case .clue(let down, let across):
            ClueCellView(down: down, across: across, side: side)
                .frame(width: side, height: side)
        case .entry:
            entryCell(r, c, side: side, value: model.solution)
        }
    }

    private func gridLines(size: Int, cell: CGFloat) -> some View {
        let total = cell * CGFloat(size)
        return Path { p in
            for i in 1..<max(size, 2) {
                let x = cell * CGFloat(i)
                p.move(to: CGPoint(x: x, y: 0)); p.addLine(to: CGPoint(x: x, y: total))
                let y = cell * CGFloat(i)
                p.move(to: CGPoint(x: 0, y: y)); p.addLine(to: CGPoint(x: total, y: y))
            }
        }
        .stroke(LCTheme.ink.opacity(0.85), lineWidth: 0.75)
    }

    @ViewBuilder
    private func selectedBorder(size: Int, cell: CGFloat) -> some View {
        if let (sr, sc) = vm.selected, sr < size, sc < size {
            Rectangle()
                .stroke(LCTheme.teal, lineWidth: 2.2)
                .frame(width: cell, height: cell)
                .position(x: cell * (CGFloat(sc) + 0.5), y: cell * (CGFloat(sr) + 0.5))
        }
    }

    @ViewBuilder
    private func entryCell(_ r: Int, _ c: Int, side: CGFloat, value: Int) -> some View {
        let key = "\(r)_\(c)"
        let isSelected = vm.selected.map { $0 == (r, c) } ?? false
        let inSelectedRun = isInSelectedRun(r, c)
        let isConflict = vm.conflicts.contains(key)
        let isWrong = vm.checkedWrong.contains(key)
        let digit = vm.filled[r][c]

        ZStack {
            Rectangle()
                .fill(cellFill(isSelected: isSelected, inRun: inSelectedRun, conflict: isConflict, wrong: isWrong))
            if digit != 0 {
                Text("\(digit)")
                    .font(.system(size: side * 0.55, weight: .semibold, design: .rounded))
                    .foregroundColor(digitColor(conflict: isConflict, wrong: isWrong))
            } else if !vm.notes[r][c].isEmpty {
                notesGrid(vm.notes[r][c], side: side)
            }
        }
        .frame(width: side, height: side)
        .contentShape(Rectangle())
        .onTapGesture { vm.select(r, c) }
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
        // Same horizontal run: same row, every cell between (inclusive) is an entry.
        if r == sr {
            let lo = min(c, sc), hi = max(c, sc)
            if (lo...hi).allSatisfy({ vm.puzzle.isEntry(r, $0) }) { return true }
        }
        // Same vertical run: same column, every cell between (inclusive) is an entry.
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
