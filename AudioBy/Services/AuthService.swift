import Foundation
import Observation
import UIKit
import AuthenticationServices
import CryptoKit
import FirebaseCore
import FirebaseAuth
import GoogleSignIn

@Observable
public final class AuthService: NSObject {
    public static let shared = AuthService()

    public static let persistSessionKey = "AudioBy.PersistSession"
    public static let rememberedEmailKey = "AudioBy.RememberedEmail"
    public static let onboardingKey = "AudioBy.HasCompletedOnboarding"

    public var isSignedIn: Bool = false
    public var currentUser: User?
    public var isBusy: Bool = false
    public var lastError: String?

    public var rememberMe: Bool = true {
        didSet { UserDefaults.standard.set(rememberMe, forKey: Self.persistSessionKey) }
    }

    public var rememberedEmail: String {
        get { UserDefaults.standard.string(forKey: Self.rememberedEmailKey) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: Self.rememberedEmailKey) }
    }

    public var displayName: String {
        let name = currentUser?.displayName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !name.isEmpty { return name }
        return currentUser?.email ?? "Listener"
    }

    public var email: String {
        currentUser?.email ?? ""
    }

    private var handle: AuthStateDidChangeListenerHandle?
    private var currentNonce: String?

    public override init() {
        super.init()
    }

    public func start() {
        FirebaseBootstrap.configure()
        if handle != nil { return }
        if UserDefaults.standard.object(forKey: Self.persistSessionKey) != nil {
            rememberMe = UserDefaults.standard.bool(forKey: Self.persistSessionKey)
        }
        if !rememberMe, Auth.auth().currentUser != nil {
            try? Auth.auth().signOut()
        }
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            self.currentUser = user
            self.isSignedIn = user != nil
        }
        configureGoogleSignIn()
    }

    private func configureGoogleSignIn() {
        guard
            let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
            let dict = NSDictionary(contentsOfFile: path),
            let clientID = dict["CLIENT_ID"] as? String
        else { return }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
    }

    public func signIn(email: String, password: String) async {
        await run {
            _ = try await Auth.auth().signIn(withEmail: email, password: password)
            self.storeRememberedEmail(email)
        }
    }

    public func signUp(name: String, email: String, password: String) async {
        await run {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let change = result.user.createProfileChangeRequest()
            change.displayName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            try await change.commitChanges()
            self.currentUser = Auth.auth().currentUser
            self.storeRememberedEmail(email)
        }
    }

    public func sendPasswordReset(email: String) async -> Bool {
        var succeeded = false
        await run {
            try await Auth.auth().sendPasswordReset(withEmail: email)
            succeeded = true
        }
        return succeeded
    }

    public func signOut() {
        lastError = nil
        try? Auth.auth().signOut()
        GIDSignIn.sharedInstance.signOut()
        isSignedIn = false
        currentUser = nil
    }

    public func signInWithGoogle() async {
        await run {
            try await self.performGoogleSignIn()
        }
    }

    @MainActor
    private func performGoogleSignIn() async throws {
        guard let presenter = Self.topViewController() else {
            throw AuthFlowError.missingPresenter
        }
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenter)
        guard let idToken = result.user.idToken?.tokenString else {
            throw AuthFlowError.missingGoogleToken
        }
        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: result.user.accessToken.tokenString
        )
        _ = try await Auth.auth().signIn(with: credential)
        if let mail = result.user.profile?.email {
            storeRememberedEmail(mail)
        }
    }

    public func handleAppleCompletion(_ authorization: ASAuthorization) async {
        await run {
            guard
                let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                let tokenData = credential.identityToken,
                let token = String(data: tokenData, encoding: .utf8),
                let nonce = self.currentNonce
            else {
                throw AuthFlowError.appleFailed
            }
            let oauth = OAuthProvider.appleCredential(
                withIDToken: token,
                rawNonce: nonce,
                fullName: credential.fullName
            )
            _ = try await Auth.auth().signIn(with: oauth)
            if let mail = credential.email {
                self.storeRememberedEmail(mail)
            }
        }
    }

    public func prepareAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = Self.randomNonceString()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = Self.sha256(nonce)
    }

    public func applyAppleFailure(_ error: Error) {
        lastError = Self.appleFailureMessage(error)
    }

    public static func appleFailureMessage(_ error: Error) -> String? {
        let nsError = error as NSError
        if nsError.domain == ASAuthorizationError.errorDomain {
            if nsError.code == ASAuthorizationError.canceled.rawValue {
                return nil
            }
            return "Sign in with Apple needs a paid Apple Developer team, the Sign in with Apple capability, and an Apple ID signed in on this device or Simulator (Settings → Sign in)."
        }
        if nsError.domain == "AKAuthenticationError" {
            return "Sign in with Apple is not available for this build. Enable automatic signing with your Apple Developer team and the Sign in with Apple capability, then run again."
        }
        return error.localizedDescription
    }

    private func storeRememberedEmail(_ email: String) {
        UserDefaults.standard.set(rememberMe, forKey: Self.persistSessionKey)
        if rememberMe {
            rememberedEmail = email
        } else {
            UserDefaults.standard.removeObject(forKey: Self.rememberedEmailKey)
        }
    }

    private func run(_ work: @escaping () async throws -> Void) async {
        await MainActor.run {
            self.isBusy = true
            self.lastError = nil
        }
        do {
            try await work()
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
        }
        await MainActor.run {
            self.isBusy = false
        }
    }

    @MainActor
    private static func topViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let window = scenes.flatMap(\.windows).first(where: \.isKeyWindow) ?? scenes.first?.windows.first
        var controller = window?.rootViewController
        while let presented = controller?.presentedViewController {
            controller = presented
        }
        return controller
    }

    private static func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            return UUID().uuidString.replacingOccurrences(of: "-", with: "")
        }
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    private static func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let hashed = SHA256.hash(data: data)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}

public enum AuthFlowError: LocalizedError {
    case missingPresenter
    case missingGoogleToken
    case appleFailed

    public var errorDescription: String? {
        switch self {
        case .missingPresenter:
            return "Could not open Google Sign-In."
        case .missingGoogleToken:
            return "Google did not return an ID token."
        case .appleFailed:
            return "Apple Sign-In did not complete."
        }
    }
}
