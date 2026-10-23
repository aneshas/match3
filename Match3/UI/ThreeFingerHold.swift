import SwiftUI
#if canImport(UIKit)
import UIKit

/// Invisible overlay that fires after three fingers are held for `seconds`. A player will
/// not do this by accident; a caregiver can. Lives only on the Play screen.
struct ThreeFingerHold: UIViewRepresentable {
    var seconds: Double = 3
    let action: () -> Void

    func makeUIView(context: Context) -> UIView {
        let view = PassthroughView()
        let press = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.fired(_:)))
        press.numberOfTouchesRequired = 3
        press.minimumPressDuration = seconds
        press.allowableMovement = 40
        view.addGestureRecognizer(press)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.action = action
    }

    func makeCoordinator() -> Coordinator { Coordinator(action: action) }

    final class Coordinator: NSObject {
        var action: () -> Void
        init(action: @escaping () -> Void) { self.action = action }

        @objc func fired(_ g: UILongPressGestureRecognizer) {
            if g.state == .began { action() }
        }
    }

    /// Lets single-finger touches through to the Play button underneath.
    final class PassthroughView: UIView {
        override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
            guard let touches = event?.allTouches, touches.count >= 3 else { return nil }
            return self
        }
    }
}
#else
struct ThreeFingerHold: View {
    var seconds: Double = 3
    let action: () -> Void
    var body: some View { Color.clear }
}
#endif
