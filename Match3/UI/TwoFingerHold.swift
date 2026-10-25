import SwiftUI
#if canImport(UIKit)
import UIKit

/// Invisible view over the logo of the Play screen that fires after two fingers are held
/// still on it for `seconds`. A player will not do this by accident, a caregiver can.
///
/// It is a plain UIKit view that owns every touch on it: an earlier version let
/// single-finger touches pass through from `hitTest`, but UIKit hit-tests the first finger
/// alone, so that finger went to the view underneath and the recognizer never saw two
/// touches. The logo has no other job, so swallowing its touches costs nothing.
struct TwoFingerHold: UIViewRepresentable {
    var seconds: Double = 3
    let action: () -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.isMultipleTouchEnabled = true
        view.addGestureRecognizer(context.coordinator.recognizer(touches: 2, seconds: seconds))
        #if DEBUG
        // A headless Simulator cannot produce two touches: one finger does it too in Debug.
        view.addGestureRecognizer(context.coordinator.recognizer(touches: 1, seconds: seconds))
        #endif
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.action = action
    }

    func makeCoordinator() -> Coordinator { Coordinator(action: action) }

    final class Coordinator: NSObject {
        var action: () -> Void
        init(action: @escaping () -> Void) { self.action = action }

        func recognizer(touches: Int, seconds: Double) -> UILongPressGestureRecognizer {
            let press = UILongPressGestureRecognizer(target: self, action: #selector(fired(_:)))
            press.numberOfTouchesRequired = touches
            press.minimumPressDuration = seconds
            press.allowableMovement = 40
            return press
        }

        @objc func fired(_ g: UILongPressGestureRecognizer) {
            if g.state == .began { action() }
        }
    }
}
#else
struct TwoFingerHold: View {
    var seconds: Double = 3
    let action: () -> Void
    var body: some View { Color.clear }
}
#endif
