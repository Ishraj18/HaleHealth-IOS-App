import SwiftUI

/// The app's primary call-to-action control. Three variants:
/// `.primary` (filled saffron), `.secondary` (forest-green ghost border),
/// `.text` (label only).
public struct HHButton: View {
    public enum Style {
        case primary, secondary, text
    }

    private let title: String
    private let style: Style
    private let isLoading: Bool
    private let isEnabled: Bool
    private let action: () -> Void

    public init(
        _ title: String,
        style: Style = .primary,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.isLoading = isLoading
        self.isEnabled = isEnabled
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            label
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(background)
                .foregroundStyle(foreground)
                .clipShape(Capsule())
                .overlay {
                    if style == .secondary {
                        Capsule().stroke(Color.hhForestGreen, lineWidth: 1.5)
                    }
                }
        }
        .buttonStyle(HHPressStyle())
        .disabled(isLoading || !isEnabled)
        .opacity(isEnabled ? 1 : 0.45)
        .animation(.hhSnappy, value: isLoading)
        .animation(.hhSnappy, value: isEnabled)
    }

    @ViewBuilder private var label: some View {
        if isLoading {
            ProgressView()
                .tint(style == .primary ? .white : .hhWarmSaffron)
        } else {
            Text(title)
                .hhFont(.hhLabel)
                .tracking(0.5)
                .textCase(.uppercase)
        }
    }

    private var background: Color {
        switch style {
        case .primary:          return .hhWarmSaffron
        case .secondary, .text: return .clear
        }
    }

    private var foreground: Color {
        switch style {
        case .primary:   return .white
        case .secondary: return .hhForestGreen
        case .text:      return .hhWarmSaffron
        }
    }
}

/// Shared press feedback: a gentle scale on the brand spring.
struct HHPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.hhSnappy, value: configuration.isPressed)
    }
}

#Preview {
    VStack(spacing: HHSpacing.md) {
        HHButton("Begin", style: .primary) {}
        HHButton("Continue", style: .secondary) {}
        HHButton("Skip for now", style: .text) {}
        HHButton("Sending…", style: .primary, isLoading: true) {}
        HHButton("Disabled", style: .primary, isEnabled: false) {}
    }
    .padding(HHSpacing.lg)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.hhBackground)
}
