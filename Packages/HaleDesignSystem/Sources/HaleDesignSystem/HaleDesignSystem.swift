import CoreText
import Foundation

/// Entry point for the Hale Health design system module.
///
/// The design system is intentionally **presentation-only**: it knows about
/// colours, type, spacing and reusable components, but nothing about domain
/// models (`Product`, `AQIReading`, …). Feature code maps domain values onto
/// the primitive parameters these components expose. This keeps the module a
/// leaf dependency that the app — and, later, the widget extension — can share.
public enum HaleDesignSystem {

    /// Registers all bundled fonts exactly once.
    ///
    /// Accessing this property is idempotent and cheap after the first call, so
    /// it is safe to reference it from the app entry point *and* from every
    /// typography accessor (which guarantees fonts are present in SwiftUI
    /// previews without any per-preview setup).
    public static let bootstrap: Void = {
        FontRegistrar.registerAll()
    }()
}

/// Registers the `.ttf` files bundled with this package via Core Text.
enum FontRegistrar {

    static func registerAll() {
        guard let resourceURL = Bundle.module.resourceURL else { return }
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(
            at: resourceURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else { return }

        for case let url as URL in enumerator {
            let ext = url.pathExtension.lowercased()
            guard ext == "ttf" || ext == "otf" else { continue }
            register(url)
        }
    }

    private static func register(_ url: URL) {
        var error: Unmanaged<CFError>?
        let ok = CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
        guard !ok, let cfError = error?.takeUnretainedValue() else { return }

        // Code 105 == kCTFontManagerErrorAlreadyRegistered — expected on
        // re-entry (e.g. repeated previews) and not worth surfacing.
        let code = CFErrorGetCode(cfError)
        if code != 105 {
            #if DEBUG
            print("⚠️ HaleDesignSystem: font registration failed for \(url.lastPathComponent): \(cfError)")
            #endif
        }
    }
}
