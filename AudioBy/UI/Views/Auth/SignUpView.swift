import SwiftUI
import AuthenticationServices

public struct SignUpView: View {
    var onShowLogin: () -> Void

    @Bindable var auth = AuthService.shared
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirm = ""

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Create your account")
                        .font(.system(size: 32, weight: .heavy))
                        .foregroundColor(Theme.textDark)
                    Text("Save progress across sessions and unlock Plus or Premium when you are ready.")
                        .font(.system(size: 15))
                        .foregroundColor(Theme.textMuted)
                }
                .padding(.top, 12)

                VStack(spacing: 16) {
                    AuthTextField(
                        title: "Name",
                        placeholder: "How should we greet you?",
                        text: $name,
                        textContentType: .name
                    )
                    AuthTextField(
                        title: "Email",
                        placeholder: "you@email.com",
                        text: $email,
                        keyboard: .emailAddress,
                        textContentType: .username
                    )
                    AuthTextField(
                        title: "Password",
                        placeholder: "At least 6 characters",
                        text: $password,
                        isSecure: true,
                        textContentType: .newPassword
                    )
                    AuthTextField(
                        title: "Confirm password",
                        placeholder: "Repeat password",
                        text: $confirm,
                        isSecure: true,
                        textContentType: .newPassword
                    )
                }

                RememberMeRow(isOn: Binding(
                    get: { auth.rememberMe },
                    set: { auth.rememberMe = $0 }
                ))

                if !confirm.isEmpty && password != confirm {
                    Text("Passwords do not match.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.red)
                }

                AuthErrorText(message: auth.lastError)

                AuthPrimaryButton(
                    title: "Create account",
                    isBusy: auth.isBusy,
                    enabled: canSubmit
                ) {
                    Task { await auth.signUp(name: name, email: email, password: password) }
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
                    Text("Already have an account?")
                        .foregroundColor(Theme.textMuted)
                    Button("Sign in") { onShowLogin() }
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
    }

    private var canSubmit: Bool {
        name.trimmingCharacters(in: .whitespaces).count >= 2
            && email.contains("@")
            && password.count >= 6
            && password == confirm
    }
}
