import SwiftUI

/// The app's loading state — three botanical dots pulsing in sequence. We never
/// show a bare `ProgressView` spinner for content loads; this keeps the brand's
/// calm, organic feel even while waiting.
public struct HHLoadingView: View {
    private let message: String?

    @State private var animating = false

    public init(message: String? = nil) {
        self.message = message
    }

    public var body: some View {
        VStack(spacing: HHSpacing.md) {
            HStack(spacing: HHSpacing.sm) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color.hhMutedSage)
                        .frame(width: 10, height: 10)
                        .scaleEffect(animating ? 1.0 : 0.55)
                        .opacity(animating ? 1.0 : 0.35)
                        .animation(
                            .easeInOut(duration: 2.2)        // a slow breath, not a spinner
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.45),
                            value: animating
                        )
                }
            }
            if let message {
                Text(message)
                    .hhFont(.hhCaption)
                    .hhText(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .onAppear { animating = true }
    }
}

#Preview {
    HHLoadingView(message: "Reading the Gurgaon air…")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.hhBackground)
}
