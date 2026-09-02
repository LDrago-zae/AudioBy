import SwiftUI

public struct ForgotPasswordView: View {
    var onBack: () -> Void

    @Bindable var auth = AuthService.shared
    @State private var email = ""
    @State private var sent = false

    public var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Button(action: onBack) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                    Text("Back to sign in")
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Theme.textDark)
            }
            .padding(.top, 8)

            VStack(alignment: .leading, spacing: 8) {
                Text("Reset password")
                    .font(.system(size: 32, weight: .heavy))
                    .foregroundColor(Theme.textDark)
                Text("We’ll email a reset link if this address has an AudioBy account.")
                    .font(.system(size: 15))
                    .foregroundColor(Theme.textMuted)
            }

            if sent {
                Text("Check your inbox. If an account exists for this email, a reset link is on its way.")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Theme.textDark)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.surfaceWhite)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Theme.cardBorder, lineWidth: 1)
                    )
            } else {
                AuthTextField(
                    title: "Email",
                    placeholder: "you@email.com",
                    text: $email,
                    keyboard: .emailAddress,
                    textContentType: .username
                )
                AuthErrorText(message: auth.lastError)
                AuthPrimaryButton(
                    title: "Send reset link",
                    isBusy: auth.isBusy,
                    enabled: email.contains("@")
                ) {
                    Task {
                        sent = await auth.sendPasswordReset(email: email)
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .background(Theme.appBackground.ignoresSafeArea())
        .onAppear {
            if email.isEmpty {
                email = auth.rememberedEmail
            }
        }
    }
}
