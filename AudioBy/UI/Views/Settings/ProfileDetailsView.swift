import SwiftUI

public struct ProfileDetailsView: View {
    @AppStorage("autoRewindOnResume") private var autoRewindOnResume: Bool = true
    @AppStorage("highQualityAudio") private var highQualityAudio: Bool = true
    @Bindable var repository = AudiobookRepository.shared
    @Bindable var playerService = AudioPlayerService.shared

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                Theme.appBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        // Profile Header Card
                        HStack(spacing: 16) {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 64, height: 64)
                                .foregroundColor(Color(red: 0.85, green: 0.70, blue: 0.60))
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 2)
                                )
                                .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Michael Kamisado")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(Theme.textDark)

                                Text("Product Design Track • Senior Level")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Theme.textMuted)

                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(Theme.brandGreen)
                                        .frame(width: 8, height: 8)
                                    Text("Active Learning Streak: 12 Days")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(Theme.brandGreen)
                                }
                                .padding(.top, 2)
                            }
                        }
                        .padding(18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                        // Skill Mastery Stats Grid
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Skill Mastery Breakdown")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(Theme.textDark)
                                .padding(.horizontal, 20)

                            HStack(spacing: 12) {
                                SkillStatBox(
                                    title: "Visual Design",
                                    score: "94%",
                                    icon: "paintpalette.fill",
                                    color: Theme.brandGreen
                                )

                                SkillStatBox(
                                    title: "Interaction",
                                    score: "86%",
                                    icon: "hand.tap.fill",
                                    color: Color(red: 0.2, green: 0.6, blue: 0.9)
                                )

                                SkillStatBox(
                                    title: "Strategy",
                                    score: "78%",
                                    icon: "chart.line.uptrend.xyaxis",
                                    color: Color(red: 0.9, green: 0.5, blue: 0.2)
                                )
                            }
                            .padding(.horizontal, 20)
                        }

                        // Audio & Learning Preferences
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Preferences")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(Theme.textDark)
                                .padding(.horizontal, 20)

                            VStack(spacing: 1) {
                                ToggleRow(
                                    title: "Auto-Rewind on Resume",
                                    subtitle: "Rewinds 3-5 seconds after long pauses",
                                    isOn: $autoRewindOnResume
                                )

                                Divider().padding(.horizontal, 16)

                                ToggleRow(
                                    title: "High Quality Lossless Audio",
                                    subtitle: "Studio grade voice narrations",
                                    isOn: $highQualityAudio
                                )
                            }
                            .background(Color.white)
                            .cornerRadius(18)
                            .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
                            .padding(.horizontal, 20)
                        }

                        // Bookmarks Count Card
                        NavigationLink(destination: BookmarksView()) {
                            HStack {
                                Image(systemName: "bookmark.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(Theme.brandGreen)
                                    .frame(width: 36, height: 36)
                                    .background(Theme.brandGreen.opacity(0.12))
                                    .clipShape(Circle())

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Saved Bookmarks & Quotes")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(Theme.textDark)
                                    Text("\(playerService.bookmarks.count) saved timestamps")
                                        .font(.system(size: 12))
                                        .foregroundColor(Theme.textMuted)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Theme.textMuted)
                            }
                            .padding(16)
                            .background(Color.white)
                            .cornerRadius(18)
                            .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
                            .padding(.horizontal, 20)
                        }

                        Spacer(minLength: 120)
                    }
                }
            }
            .navigationTitle("Profile & Stats")
        }
    }
}

private struct SkillStatBox: View {
    let title: String
    let score: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)

            Text(score)
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundColor(Theme.textDark)

            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Theme.textMuted)
                .lineLimit(1)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
    }
}

private struct ToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Theme.textDark)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textMuted)
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .tint(Theme.brandGreen)
                .labelsHidden()
        }
        .padding(16)
    }
}
