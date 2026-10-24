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
    @Environment(\.scenePhase) private var scenePhase
    @State private var autoStarted = false

    var body: some View {
        // The whole hierarchy is laid out in full-window coordinates and only the top and
        // bottom insets are re-applied as padding. Reason: on displays with a one-sided
        // horizontal inset (iPhone Duo cover screen) SwiftUI hit-testing stops at the safe
        // area edge, so candies drawn there with ignoresSafeArea could not be touched.
        GeometryReader { geo in
            ZStack {
                CandyBackground()
                screens
                    .padding(.top, geo.safeAreaInsets.top)
                    .padding(.bottom, geo.safeAreaInsets.bottom)
            }
            .environment(\.screenInsets, geo.safeAreaInsets)
            .onChange(of: geo.size, initial: true) { _, size in
                flow.boardMaxRows = BoardFit.maxRows(for: size, insets: geo.safeAreaInsets)
                if DebugFlags.autoStart, !autoStarted, flow.screen == .play {
                    autoStarted = true
                    flow.play()
                }
            }
        }
        .ignoresSafeArea()
        .sheet(isPresented: Binding(get: { flow.caregiverPanelShown }, set: { flow.caregiverPanelShown = $0 })) {
            CaregiverPanel()
                .environment(flow)
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active: MusicPlayer.shared.resume()
            case .background: MusicPlayer.shared.pause()
            default: break
            }
        }
        .task {
            MusicPlayer.shared.ensurePlaying()
            // Debug: open the caregiver panel once the window exists (presenting from init is dropped).
            guard DebugFlags.openPanel else { return }
            try? await Task.sleep(for: .milliseconds(400))
            flow.caregiverPanelShown = true
        }
    }

    @ViewBuilder private var screens: some View {
        ZStack {
            switch flow.screen {
            case .play:
                PlayScreen(onPlay: { flow.play() },
                           onCaregiverHold: { flow.caregiverPanelShown = true },
                           locked: flow.isAtLock)
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
            case .level:
                if let session = flow.session {
                    LevelScreen(session: session, onHome: { flow.goHome() })
                        .id(session.config.level)
                        .transition(.opacity)
                }
            case .goodJob:
                GoodJobScreen(nextCandy: flow.session?.nextCandy, showsLock: flow.isAtLock) { flow.continueAfterGoodJob() }
                    .transition(.scale(scale: 1.1).combined(with: .opacity))
            case .goodNight:
                GoodNightScreen { flow.endSession() }
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.45), value: flow.screen)
    }
}

/// The window's safe-area insets, for views that must keep clear of the camera even though
/// the root lays everything out in full-window coordinates.
private struct ScreenInsetsKey: EnvironmentKey {
    static let defaultValue = EdgeInsets()
}

extension EnvironmentValues {
    var screenInsets: EdgeInsets {
        get { self[ScreenInsetsKey.self] }
        set { self[ScreenInsetsKey.self] = newValue }
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
