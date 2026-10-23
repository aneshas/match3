import Foundation

/// Launch-time switches for headless testing and demos. Read from the environment, and
/// only honored in Debug builds so a shipping app can never be put in demo mode by accident.
///
///   MATCH3_AUTOSTART=1   skip the Play screen and start the current level immediately
///   MATCH3_AUTOPLAY=1    the game plays valid moves by itself (attract / verification mode)
///   MATCH3_LEVEL=12      start at this level instead of the saved one
enum DebugFlags {
    static var autoStart: Bool { flag("MATCH3_AUTOSTART") }
    static var autoPlay: Bool { flag("MATCH3_AUTOPLAY") }
    /// MATCH3_MUTE=1 silences the app for this launch only (used by headless test runs).
    static var mute: Bool { flag("MATCH3_MUTE") }
    /// MATCH3_FORGET_SWIPE=1 clears "has ever swiped" at launch so the demo shows again.
    static var forgetSwipe: Bool { flag("MATCH3_FORGET_SWIPE") }
    /// MATCH3_ASSIST=n forces the assist level for this launch (0...3).
    static var assist: Int? {
        #if DEBUG
        return ProcessInfo.processInfo.environment["MATCH3_ASSIST"].flatMap(Int.init)
        #else
        return nil
        #endif
    }

    static var startLevel: Int? {
        #if DEBUG
        return ProcessInfo.processInfo.environment["MATCH3_LEVEL"].flatMap(Int.init)
        #else
        return nil
        #endif
    }

    private static func flag(_ name: String) -> Bool {
        #if DEBUG
        return ProcessInfo.processInfo.environment[name] == "1"
        #else
        return false
        #endif
    }
}
