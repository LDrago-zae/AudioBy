import SwiftUI
import AVFoundation
import FirebaseCore
import GoogleSignIn
import RevenueCat
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseBootstrap.configure()
        AuthService.shared.start()
        RevenueCatBootstrap.configure()
        return true
    }

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        GIDSignIn.sharedInstance.handle(url)
    }
}

enum FirebaseBootstrap {
    static func configure() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
    }
}

enum RevenueCatBootstrap {
    private static var didConfigure = false

    /// Reads from process environment first, then Info.plist (`$(REVENUECAT_API_KEY)` from xcconfig).
    static var apiKey: String {
        let env = ProcessInfo.processInfo.environment["REVENUECAT_API_KEY"]?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !env.isEmpty { return env }

        let plist = (Bundle.main.object(forInfoDictionaryKey: "REVENUECAT_API_KEY") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if plist.isEmpty || plist.hasPrefix("$(") { return "" }
        return plist
    }

    static func configure() {
        guard !didConfigure else { return }
        let key = apiKey
        guard !key.isEmpty else {
            print("RevenueCat: REVENUECAT_API_KEY is not set. Purchases will be unavailable until Secrets.xcconfig is configured.")
            return
        }
        Purchases.logLevel = .warn
        Purchases.configure(withAPIKey: key)
        didConfigure = true
    }
}

@main
struct AudioByApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        FirebaseBootstrap.configure()
        RevenueCatBootstrap.configure()
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.allowAirPlay, .allowBluetoothHFP, .allowBluetoothA2DP])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session initialization warning: \(error.localizedDescription)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
