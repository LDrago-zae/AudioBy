import SwiftUI
import UIKit
import AuthenticationServices

struct AuthTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboard: UIKeyboardType = .default
    var textContentType: UITextContentType?

    @State private var isRevealed = false
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.textMuted)

            HStack(spacing: 10) {
                Group {
                    if isSecure && !isRevealed {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
                            .keyboardType(keyboard)
                            .textInputAutocapitalization(keyboard == .emailAddress ? .never : .words)
                            .autocorrectionDisabled(keyboard == .emailAddress)
                    }
                }
                .focused($focused)
                .textContentType(textContentType)
                .font(.system(size: 16))
                .foregroundColor(Theme.textDark)

                if isSecure {
                    Button {
                        isRevealed.toggle()
                    } label: {
                        Image(systemName: isRevealed ? "eye.slash" : "eye")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Theme.textMuted)
                    }
                    .accessibilityLabel(isRevealed ? "Hide password" : "Show password")
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 52)
            .background(Theme.surfaceWhite)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(focused ? Theme.brandGreen : Theme.cardBorder, lineWidth: 1)
            )
        }
    }
}

struct AuthPrimaryButton: View {
    let title: String
    var isBusy: Bool = false
    var enabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Text(title)
                    .opacity(isBusy ? 0 : 1)
                if isBusy {
                    ProgressView()
                        .tint(.black)
                }
            }
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Theme.brandGreen)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .disabled(!enabled || isBusy)
        .opacity(enabled ? 1 : 0.45)
    }
}

struct RememberMeRow: View {
    @Binding var isOn: Bool

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: isOn ? "checkmark.square.fill" : "square")
                    .font(.system(size: 20))
                    .foregroundColor(isOn ? Theme.brandGreen : Theme.textMuted)
                Text("Remember me")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.textDark)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isButton)
    }
}

struct SocialAuthButtons: View {
    var onApple: (Result<ASAuthorization, Error>) -> Void
    var onGoogle: () -> Void
    var prepareApple: (ASAuthorizationAppleIDRequest) -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 12) {
            SignInWithAppleButton(.continue, onRequest: prepareApple, onCompletion: onApple)
                .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                .frame(height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            Button(action: onGoogle) {
                HStack(spacing: 10) {
                    Text("G")
                        .font(.system(size: 18, weight: .black))
                        .foregroundColor(Color(red: 0.26, green: 0.52, blue: 0.96))
                    Text("Continue with Google")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Theme.textDark)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Theme.surfaceWhite)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Theme.cardBorder, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }
}

struct AuthOrDivider: View {
    var body: some View {
        HStack(spacing: 12) {
            Rectangle().fill(Theme.cardBorder).frame(height: 1)
            Text("or")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Theme.textMuted)
            Rectangle().fill(Theme.cardBorder).frame(height: 1)
        }
    }
}

struct AuthErrorText: View {
    let message: String?

    var body: some View {
        if let message, !message.isEmpty {
            Text(message)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.red)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
