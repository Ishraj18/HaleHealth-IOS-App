import Foundation

/// Reads environment configuration from `Info.plist`, whose values are injected
/// at build time from `Config/*.xcconfig` (and the git-ignored `Secrets.xcconfig`).
/// Never hardcode keys — they flow exclusively through this type.
enum AppConfig {

    private static func string(_ key: String) -> String {
        (Bundle.main.object(forInfoDictionaryKey: key) as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    static var supabaseURL: String { string("SUPABASE_URL") }
    static var supabaseAnonKey: String { string("SUPABASE_ANON_KEY") }
    static var aqicnToken: String { string("AQICN_TOKEN") }

    /// AQICN station slug used for the Gurgaon air-quality feed.
    static let aqiStation = "gurgaon"

    /// True only when real Supabase credentials are present (placeholders fail).
    static var isSupabaseConfigured: Bool {
        guard
            let host = URL(string: supabaseURL)?.host,
            host != "YOUR-PROJECT-REF.supabase.co",
            !supabaseAnonKey.isEmpty,
            supabaseAnonKey != "your_supabase_anon_key_here"
        else { return false }
        return true
    }

    /// True only when a real AQICN token is present.
    static var isAQIConfigured: Bool {
        !aqicnToken.isEmpty && aqicnToken != "your_aqicn_token_here"
    }
}
