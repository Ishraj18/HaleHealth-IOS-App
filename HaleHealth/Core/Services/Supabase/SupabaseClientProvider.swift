import Foundation
import Supabase

/// The single shared Supabase client. Credentials come from `AppConfig`. When
/// they're absent (e.g. a fresh checkout without `Secrets.xcconfig`), the client
/// is still constructed against a placeholder URL so the app launches; calls
/// then fail with handled `APIError`s rather than crashing on a force-unwrap.
enum SupabaseClientProvider {
    static let shared: SupabaseClient = {
        let url = URL(string: AppConfig.supabaseURL)
            ?? URL(string: "https://unconfigured.supabase.co")!
        return SupabaseClient(
            supabaseURL: url,
            supabaseKey: AppConfig.supabaseAnonKey,
            options: SupabaseClientOptions(
                auth: SupabaseClientOptions.AuthOptions(
                    redirectToURL: SupabaseAuthService.oauthRedirectURL,
                    // Opt in to the SDK's corrected behavior: the locally
                    // stored session is emitted as-is and validity is OUR
                    // responsibility — fetchCurrentProfile checks isExpired
                    // and refreshes before trusting it.
                    emitLocalSessionAsInitialSession: true
                )
            )
        )
    }()
}
