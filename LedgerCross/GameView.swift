import SwiftUI

struct GameView: View {
    @StateObject var vm: GameViewModel
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var store = LedgerStore.shared

    let title: String

    init(puzzle: LedgerPuzzle, title: String, isDaily: Bool = false, dayKey: String? = nil) {
        _vm = StateObject(wrappedValue: GameViewModel(puzzle: puzzle, isDaily: isDaily, dayKey: dayKey))
        self.title = title
    }

    var body: some View {
        GeometryReader { geo in
            let landscape = geo.size.width > geo.size.height
            ZStack {
                LCTheme.parchment.edgesIgnoringSafeArea(.all)

                if landscape {
                    landscapeLayout(geo)
                } else {
                    portraitLayout(geo)
                }

                if vm.showCelebration {
                    CelebrationOverlay(time: vm.elapsed,
                                       best: vm.bestTime,
                                       hints: vm.hintsUsed,
                                       onClose: { vm.showCelebration = false },
                                       onExit: {
                                           vm.showCelebration = false
                                           presentationMode.wrappedValue.dismiss()
                                       })
                }
            }
        }
        .navigationBarTitle(title, displayMode: .inline)
        .onAppear { vm.startTimer() }
        .onDisappear { vm.stopTimer() }
    }

    // MARK: - Layouts

    private func portraitLayout(_ geo: GeometryProxy) -> some View {
        VStack(spacing: 12) {
            topBar
            Spacer(minLength: 4)
            let boardArea = CGSize(width: geo.size.width - 24,
                                   height: geo.size.height * 0.52)
            LedgerGridView(vm: vm, available: boardArea)
            Spacer(minLength: 4)
            controlRow
            NumberPad(notesMode: vm.notesMode) { d in vm.enterDigit(d) } onErase: { vm.erase() }
                .padding(.horizontal, 12)
                .padding(.bottom, 6)
        }
        .padding(.top, 6)
    }

    private func landscapeLayout(_ geo: GeometryProxy) -> some View {
        HStack(spacing: 14) {
            let boardArea = CGSize(width: geo.size.width * 0.52,
                                   height: geo.size.height - 24)
            LedgerGridView(vm: vm, available: boardArea)
                .padding(.leading, 12)
            VStack(spacing: 12) {
                topBar
                Spacer(minLength: 2)
                controlRow
                NumberPad(notesMode: vm.notesMode) { d in vm.enterDigit(d) } onErase: { vm.erase() }
                Spacer(minLength: 2)
            }
            .padding(.trailing, 12)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Top bar (timer + difficulty)

    private var topBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 6) {
                ClockIcon(color: LCTheme.inkSoft).frame(width: 18, height: 18)
                Text(GameViewModel.formatTime(vm.elapsed))
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(LCTheme.ink)
            }
            .padding(.horizontal, 12).padding(.vertical, 7)
            .background(LCTheme.card)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(LCTheme.line, lineWidth: 1))

            Spacer()

            Text(vm.puzzle.difficulty.title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(LCTheme.teal)
                .padding(.horizontal, 12).padding(.vertical, 7)
                .background(LCTheme.tealSoft)
                .clipShape(Capsule())

            if vm.solved {
                HStack(spacing: 5) {
                    StarIcon(color: LCTheme.amber).frame(width: 16, height: 16)
                    Text("Solved")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(LCTheme.amber)
                }
                .padding(.horizontal, 12).padding(.vertical, 7)
                .background(LCTheme.amber.opacity(0.14))
                .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 14)
    }

    // MARK: - Control row

    private var controlRow: some View {
        HStack(spacing: 8) {
            controlButton(label: vm.notesMode ? "Notes On" : "Notes",
                          active: vm.notesMode,
                          icon: AnyView(PencilIcon(color: vm.notesMode ? .white : LCTheme.ink))) {
                vm.toggleNotesMode()
            }
            controlButton(label: "Undo",
                          active: false,
                          dimmed: !vm.canUndo,
                          icon: AnyView(UndoIcon(color: vm.canUndo ? LCTheme.ink : LCTheme.inkSoft.opacity(0.4)))) {
                vm.undo()
            }
            controlButton(label: "Check",
                          active: false,
                          icon: AnyView(CheckIcon(color: LCTheme.teal))) {
                vm.checkMistakes()
            }
            controlButton(label: "Hint \(vm.hintsRemaining)",
                          active: false,
                          dimmed: vm.hintsRemaining == 0,
                          icon: AnyView(LightbulbIcon(color: vm.hintsRemaining > 0 ? LCTheme.amber : LCTheme.inkSoft.opacity(0.4)))) {
                vm.revealHint()
            }
        }
        .padding(.horizontal, 12)
    }

    private func controlButton(label: String, active: Bool, dimmed: Bool = false,
                               icon: AnyView, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 5) {
                icon.frame(width: 24, height: 24)
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(active ? .white : (dimmed ? LCTheme.inkSoft.opacity(0.5) : LCTheme.ink))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(active ? LCTheme.teal : LCTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(active ? Color.clear : LCTheme.line, lineWidth: 1))
        }
        .disabled(dimmed)
    }
}

// MARK: - Number pad

struct NumberPad: View {
    let notesMode: Bool
    let onDigit: (Int) -> Void
    let onErase: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { d in digitButton(d) }
            }
            HStack(spacing: 8) {
                ForEach(6...9, id: \.self) { d in digitButton(d) }
                eraseButton
            }
        }
    }

    private func digitButton(_ d: Int) -> some View {
        Button(action: { onDigit(d) }) {
            Text("\(d)")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(notesMode ? LCTheme.teal : LCTheme.ink)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(notesMode ? LCTheme.tealSoft : LCTheme.paper)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(LCTheme.line, lineWidth: 1))
        }
    }

    private var eraseButton: some View {
        Button(action: onErase) {
            EraserIcon(color: LCTheme.red)
                .frame(width: 26, height: 26)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(LCTheme.redSoft)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(LCTheme.line, lineWidth: 1))
        }
    }
}

// MARK: - Celebration

struct CelebrationOverlay: View {
    let time: Int
    let best: Int?
    let hints: Int
    let onClose: () -> Void
    let onExit: () -> Void
    @State private var appear = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.45).edgesIgnoringSafeArea(.all)
                .onTapGesture { onClose() }
            VStack(spacing: 18) {
                ZStack {
                    Circle().fill(LCTheme.amber.opacity(0.18)).frame(width: 92, height: 92)
                    StarIcon(color: LCTheme.amber).frame(width: 54, height: 54)
                }
                .scaleEffect(appear ? 1 : 0.5)

                Text("Puzzle Solved!")
                    .font(.system(size: 24, weight: .bold, design: .serif))
                    .foregroundColor(LCTheme.ink)

                VStack(spacing: 10) {
                    statRow("Your time", GameViewModel.formatTime(time))
                    if let best = best {
                        statRow("Best time", GameViewModel.formatTime(best))
                    }
                    statRow("Hints used", "\(hints)")
                }
                .padding(.horizontal, 18).padding(.vertical, 14)
                .background(LCTheme.parchment)
                .clipShape(RoundedRectangle(cornerRadius: 14))

                HStack(spacing: 12) {
                    Button(action: onClose) {
                        Text("View Board")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(LCTheme.ink)
                            .frame(maxWidth: .infinity).padding(.vertical, 13)
                            .background(LCTheme.card)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(LCTheme.line, lineWidth: 1))
                    }
                    Button(action: onExit) {
                        Text("Done")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 13)
                            .background(LCTheme.teal)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding(24)
            .background(LCTheme.paper)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(LCTheme.line, lineWidth: 1))
            .padding(.horizontal, 36)
            .scaleEffect(appear ? 1 : 0.85)
            .opacity(appear ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) { appear = true }
        }
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.system(size: 14, weight: .medium)).foregroundColor(LCTheme.inkSoft)
            Spacer()
            Text(value).font(.system(size: 16, weight: .bold, design: .rounded)).foregroundColor(LCTheme.ink)
        }
        .frame(width: 200)
    }
}
