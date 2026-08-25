import SwiftUI
import AVFoundation

@main
struct AudioByApp: App {
    init() {
        // Configure audio session on startup
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.allowAirPlay, .allowBluetooth, .allowBluetoothA2DP])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session initialization warning: \(error.localizedDescription)")
        }
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
    }
}
