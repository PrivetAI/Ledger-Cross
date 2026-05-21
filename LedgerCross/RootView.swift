import SwiftUI

struct RootView: View {
    @ObservedObject private var store = LedgerStore.shared
    @State private var showOnboarding = false

    var body: some View {
        ZStack {
            NavigationView {
                HomeView()
            }
            .navigationViewStyle(StackNavigationViewStyle())

            if showOnboarding {
                OnboardingView {
                    store.settings.onboardingDone = true
                    store.saveSettings()
                    withAnimation { showOnboarding = false }
                }
                .transition(.opacity)
                .zIndex(10)
            }
        }
        .onAppear {
            if !store.settings.onboardingDone {
                showOnboarding = true
            }
            // Warm up the first pack in the background for snappier navigation.
            DispatchQueue.global(qos: .utility).async {
                LedgerCatalog.shared.warmPack(.easy)
            }
        }
    }
}
