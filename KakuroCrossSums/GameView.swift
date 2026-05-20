import SwiftUI

struct GameView: View {
    @StateObject var vm: GameViewModel
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var store = KakuroStore.shared

    let title: String

    init(puzzle: KakuroPuzzle, title: String, isDaily: Bool = false, dayKey: String? = nil) {
        _vm = StateObject(wrappedValue: GameViewModel(puzzle: puzzle, isDaily: isDaily, dayKey: dayKey))
        self.title = title
    }

    var body: some View {
        GeometryReader { geo in
            let landscape = geo.size.width > geo.size.height
            ZStack {
                KCSTheme.parchment.edgesIgnoringSafeArea(.all)

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
            KakuroGridView(vm: vm, available: boardArea)
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
            KakuroGridView(vm: vm, available: boardArea)
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
                ClockIcon(color: KCSTheme.inkSoft).frame(width: 18, height: 18)
                Text(GameViewModel.formatTime(vm.elapsed))
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(KCSTheme.ink)
            }
            .padding(.horizontal, 12).padding(.vertical, 7)
            .background(KCSTheme.card)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(KCSTheme.line, lineWidth: 1))

            Spacer()

            Text(vm.puzzle.difficulty.title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(KCSTheme.teal)
                .padding(.horizontal, 12).padding(.vertical, 7)
                .background(KCSTheme.tealSoft)
                .clipShape(Capsule())

            if vm.solved {
                HStack(spacing: 5) {
                    StarIcon(color: KCSTheme.amber).frame(width: 16, height: 16)
                    Text("Solved")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(KCSTheme.amber)
                }
                .padding(.horizontal, 12).padding(.vertical, 7)
                .background(KCSTheme.amber.opacity(0.14))
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
                          icon: AnyView(PencilIcon(color: vm.notesMode ? .white : KCSTheme.ink))) {
                vm.toggleNotesMode()
            }
            controlButton(label: "Undo",
                          active: false,
                          dimmed: !vm.canUndo,
                          icon: AnyView(UndoIcon(color: vm.canUndo ? KCSTheme.ink : KCSTheme.inkSoft.opacity(0.4)))) {
                vm.undo()
            }
            controlButton(label: "Check",
                          active: false,
                          icon: AnyView(CheckIcon(color: KCSTheme.teal))) {
                vm.checkMistakes()
            }
            controlButton(label: "Hint \(vm.hintsRemaining)",
                          active: false,
                          dimmed: vm.hintsRemaining == 0,
                          icon: AnyView(LightbulbIcon(color: vm.hintsRemaining > 0 ? KCSTheme.amber : KCSTheme.inkSoft.opacity(0.4)))) {
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
                    .foregroundColor(active ? .white : (dimmed ? KCSTheme.inkSoft.opacity(0.5) : KCSTheme.ink))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(active ? KCSTheme.teal : KCSTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(active ? Color.clear : KCSTheme.line, lineWidth: 1))
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
                .foregroundColor(notesMode ? KCSTheme.teal : KCSTheme.ink)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(notesMode ? KCSTheme.tealSoft : KCSTheme.paper)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(KCSTheme.line, lineWidth: 1))
        }
    }

    private var eraseButton: some View {
        Button(action: onErase) {
            EraserIcon(color: KCSTheme.red)
                .frame(width: 26, height: 26)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(KCSTheme.redSoft)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(KCSTheme.line, lineWidth: 1))
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
                    Circle().fill(KCSTheme.amber.opacity(0.18)).frame(width: 92, height: 92)
                    StarIcon(color: KCSTheme.amber).frame(width: 54, height: 54)
                }
                .scaleEffect(appear ? 1 : 0.5)

                Text("Puzzle Solved!")
                    .font(.system(size: 24, weight: .bold, design: .serif))
                    .foregroundColor(KCSTheme.ink)

                VStack(spacing: 10) {
                    statRow("Your time", GameViewModel.formatTime(time))
                    if let best = best {
                        statRow("Best time", GameViewModel.formatTime(best))
                    }
                    statRow("Hints used", "\(hints)")
                }
                .padding(.horizontal, 18).padding(.vertical, 14)
                .background(KCSTheme.parchment)
                .clipShape(RoundedRectangle(cornerRadius: 14))

                HStack(spacing: 12) {
                    Button(action: onClose) {
                        Text("View Board")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(KCSTheme.ink)
                            .frame(maxWidth: .infinity).padding(.vertical, 13)
                            .background(KCSTheme.card)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(KCSTheme.line, lineWidth: 1))
                    }
                    Button(action: onExit) {
                        Text("Done")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 13)
                            .background(KCSTheme.teal)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding(24)
            .background(KCSTheme.paper)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(KCSTheme.line, lineWidth: 1))
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
            Text(label).font(.system(size: 14, weight: .medium)).foregroundColor(KCSTheme.inkSoft)
            Spacer()
            Text(value).font(.system(size: 16, weight: .bold, design: .rounded)).foregroundColor(KCSTheme.ink)
        }
        .frame(width: 200)
    }
}
