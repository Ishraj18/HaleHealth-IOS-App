import SwiftUI
import UIKit

/// Brand-styled text field: parchment fill, sage placeholder, charcoal text,
/// and a forest-green focus ring.
public struct HHTextField: View {
    private let placeholder: String
    @Binding private var text: String
    private let keyboardType: UIKeyboardType
    private let textContentType: UITextContentType?
    private let isSecure: Bool
    private let autocapitalization: TextInputAutocapitalization
    private let submitLabel: SubmitLabel

    @FocusState private var isFocused: Bool
    @Environment(\.hhAtmosphere) private var atmosphere

    public init(
        _ placeholder: String,
        text: Binding<String>,
        keyboardType: UIKeyboardType = .default,
        textContentType: UITextContentType? = nil,
        isSecure: Bool = false,
        autocapitalization: TextInputAutocapitalization = .sentences,
        submitLabel: SubmitLabel = .return
    ) {
        self.placeholder = placeholder
        self._text = text
        self.keyboardType = keyboardType
        self.textContentType = textContentType
        self.isSecure = isSecure
        self.autocapitalization = autocapitalization
        self.submitLabel = submitLabel
    }

    public var body: some View {
        field
            .focused($isFocused)
            .keyboardType(keyboardType)
            .textContentType(textContentType)
            .textInputAutocapitalization(autocapitalization)
            .autocorrectionDisabled(keyboardType == .emailAddress)
            .submitLabel(submitLabel)
            .hhFont(.hhBody)
            .hhText(.primary)
            .tint(.hhForestGreen)
            .padding(.horizontal, HHSpacing.md)
            .frame(height: 52)
            .background(
                atmosphere.fieldFill,
                in: RoundedRectangle(cornerRadius: HHRadius.md, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: HHRadius.md, style: .continuous)
                    .stroke(
                        isFocused ? Color.hhMutedSage : atmosphere.border,
                        lineWidth: isFocused ? 1.5 : 1
                    )
            }
            .animation(.hhGentle, value: isFocused)
    }

    @ViewBuilder private var field: some View {
        if isSecure {
            SecureField("", text: $text, prompt: prompt)
        } else {
            TextField("", text: $text, prompt: prompt)
        }
    }

    private var prompt: Text {
        Text(placeholder).foregroundStyle(atmosphere.textSecondary)
    }
}

#Preview {
    struct PreviewHost: View {
        @State private var email = ""
        @State private var code = ""
        var body: some View {
            VStack(spacing: HHSpacing.md) {
                HHTextField("you@example.com", text: $email,
                            keyboardType: .emailAddress,
                            textContentType: .emailAddress,
                            autocapitalization: .never)
                HHTextField("6-digit code", text: $code,
                            keyboardType: .numberPad)
            }
            .padding(HHSpacing.lg)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.hhBackground)
        }
    }
    return PreviewHost()
}
