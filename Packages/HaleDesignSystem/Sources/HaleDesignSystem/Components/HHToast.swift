import SwiftUI

/// The semantic flavour of a toast.
public enum HHToastStyle: Equatable {
    case success, error, info

    var color: Color {
        switch self {
        case .success: return .hhAQIGood
        case .error:   return .hhAQIUnhealthy
        case .info:    return .hhForestGreen
        }
    }

    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error:   return "exclamationmark.triangle.fill"
        case .info:    return "info.circle.fill"
        }
    }
}

/// A toast payload. Identity drives the auto-dismiss timer, so showing a new
/// toast while one is visible restarts the clock cleanly.
public struct HHToastData: Equatable, Identifiable {
    public let id = UUID()
    public let message: String
    public let style: HHToastStyle

    public init(message: String, style: HHToastStyle) {
        self.message = message
        self.style = style
    }
}

/// The toast visual — a frosted, bottom-anchored banner.
public struct HHToastView: View {
    private let data: HHToastData

    public init(_ data: HHToastData) {
        self.data = data
    }

    public var body: some View {
        HStack(spacing: HHSpacing.sm) {
            Image(systemName: data.style.icon)
                .foregroundStyle(data.style.color)
            Text(data.message)
                .hhFont(.hhSubheading)
                .hhText(.primary)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, HHSpacing.md)
        .padding(.vertical, HHSpacing.sm + 2)
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: HHRadius.md, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: HHRadius.md, style: .continuous)
                .stroke(data.style.color.opacity(0.25), lineWidth: 1)
        }
        .hhShadow(HHShadow.float)
    }
}

private struct HHToastModifier: ViewModifier {
    @Binding var data: HHToastData?
    let duration: TimeInterval

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let data {
                    HHToastView(data)
                        .padding(.horizontal, HHSpacing.md)
                        .padding(.bottom, HHSpacing.md)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .task(id: data.id) {
                            // Auto-dismiss. do/catch (not try?) honours the
                            // project rule of never swallowing errors silently.
                            do {
                                try await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
                            } catch {
                                return // cancelled (e.g. replaced by a newer toast)
                            }
                            withAnimation(.hhSpring) { self.data = nil }
                        }
                }
            }
            .animation(.hhSpring, value: data)
    }
}

public extension View {
    /// Presents a bottom-anchored toast bound to optional state, auto-dismissing
    /// after `duration` seconds.
    func hhToast(_ data: Binding<HHToastData?>, duration: TimeInterval = 3) -> some View {
        modifier(HHToastModifier(data: data, duration: duration))
    }
}

#Preview {
    struct PreviewHost: View {
        @State private var toast: HHToastData? = HHToastData(
            message: "We've sent a code to your email.",
            style: .success
        )
        var body: some View {
            VStack {
                HHButton("Show toast") {
                    toast = HHToastData(message: "Something went wrong.", style: .error)
                }
            }
            .padding(HHSpacing.lg)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.hhBackground)
            .hhToast($toast)
        }
    }
    return PreviewHost()
}
