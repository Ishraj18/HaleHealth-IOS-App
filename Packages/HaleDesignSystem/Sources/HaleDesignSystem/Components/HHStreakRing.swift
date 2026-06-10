import SwiftUI

/// Apple-rings-style progress ring with a flame streak count in the centre.
public struct HHStreakRing: View {
    private let progress: Double      // 0…1 today's completion
    private let streak: Int
    private let size: CGFloat

    public init(progress: Double, streak: Int, size: CGFloat = 96) {
        self.progress = min(max(progress, 0), 1)
        self.streak = streak
        self.size = size
    }

    public var body: some View {
        ZStack {
            Circle()
                .stroke(Color.hhBorder.opacity(0.6), lineWidth: size * 0.09)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [.hhWarmSaffron, .hhDustyGold, .hhWarmSaffron],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: size * 0.09, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.hhSpring, value: progress)

            VStack(spacing: 0) {
                Text("\(streak)")
                    .hhFont(.hhDisplay2, lineSpacing: 0)
                    .hhText(.display)
                Text(streak == 1 ? "day" : "days")
                    .hhFont(.hhOverline, lineSpacing: 0)
                    .tracking(0.8)
                    .textCase(.uppercase)
                    .hhText(.secondary)
            }
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    HStack(spacing: HHSpacing.lg) {
        HHStreakRing(progress: 0.35, streak: 3)
        HHStreakRing(progress: 1.0, streak: 14)
    }
    .padding(HHSpacing.lg)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.hhBackground)
}
