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
