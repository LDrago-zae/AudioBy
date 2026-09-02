import SwiftUI

public struct SplashView: View {
    public var body: some View {
        ZStack {
            Theme.appBackground.ignoresSafeArea()

            VStack(spacing: 20) {
                ZStack {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Theme.brandGreen)
                        .frame(width: 88, height: 88)
                    Image(systemName: "headphones")
                        .font(.system(size: 38, weight: .semibold))
                        .foregroundColor(.black)
                }

                VStack(spacing: 6) {
                    Text("AudioBy")
                        .font(.system(size: 34, weight: .heavy))
                        .foregroundColor(Theme.textDark)
                    Text("Public-domain listening")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Theme.textMuted)
                }
            }
        }
    }
}
