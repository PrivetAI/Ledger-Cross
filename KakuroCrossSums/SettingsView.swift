import SwiftUI

struct SettingsView: View {
    @ObservedObject private var store = KakuroStore.shared
    @State private var showPrivacy = false
    @State private var showResetConfirm = false
    @State private var showHowTo = false
    @State private var showOnboarding = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                groupCard(title: "Gameplay") {
                    toggleRow(title: "Sound Effects", isOn: $store.settings.soundOn)
                    divider
                    toggleRow(title: "Haptics", isOn: $store.settings.hapticsOn)
                    divider
                    toggleRow(title: "Auto-check mistakes", isOn: $store.settings.autoCheck)
                }

                groupCard(title: "Help") {
                    tapRow(title: "How to Play", action: { showHowTo = true })
                    divider
                    tapRow(title: "Replay Tutorial", action: { showOnboarding = true })
                }

                groupCard(title: "About") {
                    tapRow(title: "Privacy Policy", action: { showPrivacy = true })
                    divider
                    HStack {
                        Text("Version").font(.system(size: 15, weight: .medium)).foregroundColor(KCSTheme.ink)
                        Spacer()
                        Text("1.0").font(.system(size: 15, weight: .medium)).foregroundColor(KCSTheme.inkSoft)
                    }
                    .padding(.vertical, 12).padding(.horizontal, 14)
                }

                groupCard(title: "Data") {
                    Button(action: { showResetConfirm = true }) {
                        HStack {
                            Text("Reset Progress")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(KCSTheme.red)
                            Spacer()
                        }
                        .padding(.vertical, 12).padding(.horizontal, 14)
                    }
                }

                Text("Resets all puzzle progress, best times, and streaks.")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(KCSTheme.inkSoft)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)

                Color.clear.frame(height: 8)
            }
            .padding(16)
        }
        .background(KCSTheme.parchment.edgesIgnoringSafeArea(.all))
        .navigationBarTitle("Settings", displayMode: .inline)
        .onChange(of: store.settings.soundOn) { _ in store.saveSettings() }
        .onChange(of: store.settings.hapticsOn) { _ in store.saveSettings() }
        .onChange(of: store.settings.autoCheck) { _ in store.saveSettings() }
        .sheet(isPresented: $showPrivacy) {
            KakuroCrossSumsWebPanel(urlString: "https://example.com")
                .edgesIgnoringSafeArea(.all)
        }
        .sheet(isPresented: $showHowTo) {
            NavigationView { HowToPlayView() }
                .navigationViewStyle(StackNavigationViewStyle())
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView { showOnboarding = false }
        }
        .alert(isPresented: $showResetConfirm) {
            Alert(
                title: Text("Reset Progress?"),
                message: Text("This will permanently erase all puzzle progress, best times, and daily streaks."),
                primaryButton: .destructive(Text("Reset")) {
                    store.resetAll()
                    KCSFeedback.error()
                },
                secondaryButton: .cancel()
            )
        }
    }

    private var divider: some View {
        Rectangle().fill(KCSTheme.line).frame(height: 1).padding(.leading, 14)
    }

    private func groupCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(KCSTheme.inkSoft)
                .padding(.leading, 6).padding(.bottom, 8)
            VStack(spacing: 0) { content() }
                .background(KCSTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(KCSTheme.line, lineWidth: 1))
        }
    }

    private func toggleRow(title: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Text(title).font(.system(size: 15, weight: .medium)).foregroundColor(KCSTheme.ink)
        }
        .toggleStyle(KCSToggleStyle())
        .padding(.vertical, 10).padding(.horizontal, 14)
    }

    private func tapRow(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title).font(.system(size: 15, weight: .medium)).foregroundColor(KCSTheme.ink)
                Spacer()
                ChevronIcon(color: KCSTheme.inkSoft).frame(width: 16, height: 16)
            }
            .padding(.vertical, 12).padding(.horizontal, 14)
        }
    }
}

// Custom toggle (no system tint reliance on theme; teal track).
struct KCSToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer()
            ZStack {
                Capsule()
                    .fill(configuration.isOn ? KCSTheme.teal : KCSTheme.line)
                    .frame(width: 48, height: 28)
                Circle()
                    .fill(Color.white)
                    .frame(width: 22, height: 22)
                    .offset(x: configuration.isOn ? 10 : -10)
                    .shadow(color: Color.black.opacity(0.12), radius: 1, y: 1)
            }
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.18)) { configuration.isOn.toggle() }
                KCSFeedback.tap()
            }
        }
    }
}
