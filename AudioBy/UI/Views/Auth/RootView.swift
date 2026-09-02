import SwiftUI

private enum AuthRoute {
    case login
    case signUp
    case forgot
}

public struct RootView: View {
    @Bindable var auth = AuthService.shared
    @AppStorage("isDarkMode") private var isDarkMode: Bool = true
    @State private var showSplash = true
    @State private var hasOnboarded = UserDefaults.standard.bool(forKey: AuthService.onboardingKey)
    @State private var route: AuthRoute = .login

    public var body: some View {
        ZStack {
            Theme.appBackground.ignoresSafeArea()

            if showSplash {
                SplashView()
            } else if !hasOnboarded {
                OnboardingView {
                    hasOnboarded = true
                }
            } else if auth.isSignedIn {
                MainTabView()
                    .task {
                        await CatalogStore.shared.refreshFromRemoteIfNeeded()
                    }
            } else {
                Group {
                    switch route {
                    case .login:
                        LoginView(
                            onShowSignUp: { route = .signUp },
                            onForgotPassword: { route = .forgot }
                        )
                    case .signUp:
                        SignUpView(onShowLogin: { route = .login })
                    case .forgot:
                        ForgotPasswordView(onBack: { route = .login })
                    }
                }
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .task {
            try? await Task.sleep(for: .milliseconds(1200))
            withAnimation(.easeOut(duration: 0.25)) {
                showSplash = false
            }
        }
    }
}
