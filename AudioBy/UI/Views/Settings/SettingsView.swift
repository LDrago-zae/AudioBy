import SwiftUI

public struct SettingsView: View {
    @AppStorage("autoRewindOnResume") private var autoRewindOnResume: Bool = true
    @AppStorage("downloadWifiOnly") private var downloadWifiOnly: Bool = true
    @AppStorage("highQualityAudio") private var highQualityAudio: Bool = true
    @AppStorage("defaultSkipInterval") private var defaultSkipInterval: Int = 15

    public init() {}

    public var body: some View {
        ProfileDetailsView()
    }
}
