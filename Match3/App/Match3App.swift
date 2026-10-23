import SwiftUI

@main
struct Match3App: App {
    @State private var flow = AppFlow()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(flow)
                .preferredColorScheme(.light)
                .hideStatusBar()
        }
    }
}

/// Switches between the three screens over one shared background. There is no navigation
/// stack: the player can only ever be on one of these, and the only way forward is
/// Play / finishing a level.
struct RootView: View {
    @Environment(AppFlow.self) private var flow

    var body: some View {
        ZStack {
            CandyBackground()
            switch flow.screen {
            case .play:
                PlayScreen(onPlay: { flow.play() },
                           onCaregiverHold: { flow.caregiverPanelShown = true },
                           completedLevels: flow.completedLevels)
                    .centeredOnScreen()
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
            case .level:
                if let session = flow.session {
                    LevelScreen(session: session)
                        .id(session.config.level)
                        .transition(.opacity)
                }
            case .goodJob:
                GoodJobScreen { flow.continueAfterGoodJob() }
                    .centeredOnScreen()
                    .transition(.scale(scale: 1.1).combined(with: .opacity))
            case .goodNight:
                GoodNightScreen { flow.endSession() }
                    .centeredOnScreen()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.45), value: flow.screen)
        .sheet(isPresented: Binding(get: { flow.caregiverPanelShown }, set: { flow.caregiverPanelShown = $0 })) {
            CaregiverPanel()
                .environment(flow)
        }
        .task {
            // Debug: open the caregiver panel once the window exists (presenting from init is dropped).
            guard DebugFlags.openPanel else { return }
            try? await Task.sleep(for: .milliseconds(400))
            flow.caregiverPanelShown = true
        }
    }
}

extension View {
    /// Some displays (the folded iPhone Duo cover screen, for one) have a large one-sided
    /// horizontal safe-area inset. Content centered inside the safe area then sits visibly
    /// off-center. Centering on the full width fixes that; the top and bottom insets still
    /// apply, which keeps content clear of the camera.
    func centeredOnScreen() -> some View {
        ignoresSafeArea(.container, edges: .horizontal)
    }
}

private extension View {
    func hideStatusBar() -> some View {
        #if os(iOS)
        return statusBarHidden(true)
        #else
        return self
        #endif
    }
}
