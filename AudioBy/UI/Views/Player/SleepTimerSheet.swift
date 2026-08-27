import SwiftUI

public struct SleepTimerSheet: View {
    @Environment(\.dismiss) private var dismiss
    public let activeOption: SleepTimerOption
    public let onSelectOption: (SleepTimerOption) -> Void

    private let options: [SleepTimerOption] = [
        .off,
        .fiveMinutes,
        .fifteenMinutes,
        .thirtyMinutes,
        .fortyFiveMinutes,
        .sixtyMinutes,
        .endOfChapter
    ]

    public var body: some View {
        NavigationStack {
            ZStack {
                Theme.appBackground.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Sleep Timer")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                            Text("Playback will automatically stop after the timer ends.")
                                .font(.system(size: 13))
                                .foregroundColor(Theme.textMuted)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    VStack(spacing: 8) {
                        ForEach(options, id: \.self) { option in
                            Button {
                                onSelectOption(option)
                                dismiss()
                            } label: {
                                HStack {
                                    Image(systemName: iconName(for: option))
                                        .font(.system(size: 16))
                                        .foregroundColor(activeOption == option ? Theme.brandGreen : Theme.textMuted)
                                        .frame(width: 28)

                                    Text(option.title)
                                        .font(.system(size: 16, weight: activeOption == option ? .bold : .regular))
                                        .foregroundColor(activeOption == option ? Theme.brandGreen : .white)

                                    Spacer()

                                    if activeOption == option {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 18))
                                            .foregroundColor(Theme.brandGreen)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(activeOption == option ? Theme.brandGreen.opacity(0.12) : Theme.surfaceWhite)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(activeOption == option ? Theme.brandGreen.opacity(0.35) : Theme.cardBorder, lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    Spacer()
                }
            }
            .presentationDetents([.height(520)])
            .presentationDragIndicator(.visible)
        }
    }

    private func iconName(for option: SleepTimerOption) -> String {
        switch option {
        case .off: return "moon.slash"
        case .fiveMinutes, .fifteenMinutes, .thirtyMinutes, .fortyFiveMinutes, .sixtyMinutes: return "moon.stars.fill"
        case .endOfChapter: return "bookmark.circle.fill"
        case .custom: return "timer"
        }
    }
}
