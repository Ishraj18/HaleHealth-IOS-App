import SwiftUI
import HaleDesignSystem

/// Pre-session choice of breath pattern and duration, then into the clearing.
struct ShuddhiSetupView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var pattern = BreathPattern.all[0]
    @State private var minutes = 5
    @State private var inSession = false

    var body: some View {
        VStack(alignment: .leading, spacing: HHSpacing.lg) {
            HStack {
                VStack(alignment: .leading, spacing: HHSpacing.xs) {
                    Text("Shuddhi")
                        .hhFont(.hhDisplay1)
                        .foregroundStyle(Color.hhCreamParchment)
                    Text(introLine)
                        .hhFont(.hhDisplayItalic)
                        .foregroundStyle(Color.hhMutedSage)
                }
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(Color.hhMutedSage)
                        .padding(HHSpacing.sm)
                }
            }

            ScrollView(showsIndicators: false) {
                VStack(spacing: HHSpacing.sm) {
                    ForEach(BreathPattern.all) { p in
                        patternRow(p)
                    }
                }
            }

            VStack(alignment: .leading, spacing: HHSpacing.sm) {
                Text("DURATION")
                    .hhFont(.hhOverline)
                    .tracking(1)
                    .foregroundStyle(Color.hhMutedSage)
                HStack(spacing: HHSpacing.sm) {
                    ForEach([1, 3, 5, 10, 15, 20], id: \.self) { m in
                        Button {
                            withAnimation(.hhSnappy) { minutes = m }
                        } label: {
                            Text("\(m)m")
                                .hhFont(.hhLabel)
                                .foregroundStyle(minutes == m ? Color.hhForestGreen : Color.hhCreamParchment)
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                                .background(
                                    minutes == m ? Color.hhCreamParchment : Color.white.opacity(0.08),
                                    in: Capsule()
                                )
                        }
                    }
                }
            }

            HHButton("Begin clearing", style: .primary) { inSession = true }
        }
        .padding(HHSpacing.lg)
        .background(Color.hhForestGreen.ignoresSafeArea())
        .fullScreenCover(isPresented: $inSession) {
            ShuddhiSessionView(pattern: pattern, minutes: minutes) { completed in
                // X returns to this options page; a finished sitting goes home.
                inSession = false
                if completed { dismiss() }
            }
        }
    }

    private var introLine: String {
        guard let aqi = appState.currentAQI else { return "Clear your air." }
        switch aqi.category {
        case .good, .moderate: return "A clear day outside. Clear the inside too."
        default: return "The air is heavy today. Clear yours."
        }
    }

    private func patternRow(_ p: BreathPattern) -> some View {
        let selected = pattern == p
        let accent = Color(hex: p.accentHex)
        return Button {
            withAnimation(.hhSnappy) { pattern = p }
        } label: {
            HStack(spacing: HHSpacing.md) {
                Circle().fill(accent).frame(width: 10, height: 10)
                VStack(alignment: .leading, spacing: 2) {
                    Text(p.name)
                        .hhFont(.hhHeading)
                        .foregroundStyle(Color.hhCreamParchment)
                    Text("\(p.subtitle) · \(p.bestFor)")
                        .hhFont(.hhCaption)
                        .foregroundStyle(Color.hhMutedSage)
                }
                Spacer()
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selected ? accent : Color.hhMutedSage.opacity(0.4))
            }
            .padding(HHSpacing.md)
            .background(
                Color.white.opacity(selected ? 0.12 : 0.05),
                in: RoundedRectangle(cornerRadius: HHRadius.md, style: .continuous)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ShuddhiSetupView().environmentObject(AppState.preview)
}
