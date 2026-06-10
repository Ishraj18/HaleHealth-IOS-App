import OSLog

/// Thin, categorised wrapper over the unified logging system. Use these instead
/// of `print` so logs are structured, filterable, and stripped appropriately in
/// release builds.
enum Log {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.halehealthindia.app"

    static let app     = Logger(subsystem: subsystem, category: "app")
    static let network = Logger(subsystem: subsystem, category: "network")
    static let auth    = Logger(subsystem: subsystem, category: "auth")
    static let aqi     = Logger(subsystem: subsystem, category: "aqi")
    static let ui      = Logger(subsystem: subsystem, category: "ui")
}
