import SwiftUI
import AuthenticationServices

public struct LoginView: View {
    var onShowSignUp: () -> Void
    var onForgotPassword: () -> Void

    @Bindable var auth = AuthService.shared
    @State private var email = ""
    @State private var password = ""

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Welcome back")
                        .font(.system(size: 32, weight: .heavy))
                        .foregroundColor(Theme.textDark)
                    Text("Sign in to keep your library, progress, and downloads on this device.")
                        .font(.system(size: 15))
                        .foregroundColor(Theme.textMuted)
                }
                .padding(.top, 12)

                VStack(spacing: 16) {
                    AuthTextField(
                        title: "Email",
                        placeholder: "you@email.com",
                        text: $email,
                        keyboard: .emailAddress,
                        textContentType: .username
                    )
                    AuthTextField(
                        title: "Password",
                        placeholder: "Your password",
                        text: $password,
                        isSecure: true,
                        textContentType: .password
                    )
                }

                HStack {
                    RememberMeRow(isOn: Binding(
                        get: { auth.rememberMe },
                        set: { auth.rememberMe = $0 }
                    ))
                    Spacer()
                    Button("Forgot password?") { onForgotPassword() }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.brandGreen)
                }

                AuthErrorText(message: auth.lastError)

                AuthPrimaryButton(
                    title: "Sign in",
                    isBusy: auth.isBusy,
                    enabled: canSubmit
                ) {
                    Task { await auth.signIn(email: email, password: password) }
                }

                AuthOrDivider()

                SocialAuthButtons(
                    onApple: { result in
                        switch result {
                        case .success(let authorization):
                            Task { await auth.handleAppleCompletion(authorization) }
                        case .failure(let error):
                            auth.applyAppleFailure(error)
                        }
                    },
                    onGoogle: {
                        Task { await auth.signInWithGoogle() }
                    },
                    prepareApple: { request in
                        auth.prepareAppleRequest(request)
                    }
                )

                HStack(spacing: 4) {
                    Text("New here?")
                        .foregroundColor(Theme.textMuted)
                    Button("Create an account") { onShowSignUp() }
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.brandGreen)
                }
                .font(.system(size: 15))
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.appBackground.ignoresSafeArea())
        .onAppear {
            if email.isEmpty {
                email = auth.rememberedEmail
            }
        }
    }

    private var canSubmit: Bool {
        email.contains("@") && password.count >= 6
    }
}
