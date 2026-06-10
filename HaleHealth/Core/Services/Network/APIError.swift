import Foundation

/// The single error type surfaced by the service layer. Every thrown error is
/// caught, logged, and shown to the user — never swallowed with `try?`.
enum APIError: LocalizedError {
    case invalidResponse
    case decodingFailed(String)
    case networkUnavailable
    case notConfigured(String)
    case authFailed(String)
    case supabaseError(String)
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:        return "The server returned an unexpected response."
        case .decodingFailed(let m):  return "We couldn't read the data: \(m)"
        case .networkUnavailable:     return "No internet connection."
        case .notConfigured(let m):   return m
        case .authFailed(let m):      return m
        case .supabaseError(let m):   return m
        case .unknown(let e):         return e.localizedDescription
        }
    }
}
