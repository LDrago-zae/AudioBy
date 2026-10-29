import SwiftUI

public struct SplashView: View {
    public var body: some View {
        ZStack {
            Theme.appBackground.ignoresSafeArea()

            VStack(spacing: 20) {
                ZStack {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Theme.ember)
                        .frame(width: 88, height: 88)
                    AudioByMark()
                        .fill(style: FillStyle(eoFill: true))
                        .foregroundStyle(Color.white)
                        .frame(width: 46, height: 46)
                }

                VStack(spacing: 6) {
                    Text("AudioBy")
                        .font(.system(size: 34, weight: .heavy))
                        .foregroundColor(Theme.textDark)
                    Text("Listen · Read · Manga")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Theme.textMuted)
                }
            }
        }
    }
}
