import SwiftUI

public struct ActivityStatsView: View {
    @Bindable var playerService = AudioPlayerService.shared
    @State private var stats: UserListeningStats = StorageService.shared.loadStats()
    @State private var showingGoalPicker = false

    public init() {}

    private let weekDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    public var body: some View {
        NavigationStack {
            ZStack {
                Theme.appBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        // Streak Hero Card
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.orange, Color.red],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 60, height: 60)
                                    .shadow(color: Color.orange.opacity(0.4), radius: 8, x: 0, y: 4)

                                Image(systemName: "flame.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("\(stats.streakDays) Days")
                                        .font(.system(size: 24, weight: .black, design: .rounded))
                                        .foregroundColor(Theme.textDark)
                                    Text("STREAK")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.orange)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.orange.opacity(0.15))
                                        .clipShape(Capsule())
                                }

                                Text(stats.streakDays == 0 ? "Listen today to start your streak." : "You've listened on consecutive days. Keep it going.")
                                    .font(.system(size: 13))
                                    .foregroundColor(Theme.textMuted)
                                    .lineLimit(2)
                            }
                        }
                        .padding(18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.surfaceWhite)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Theme.cardBorder, lineWidth: 1)
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                        // Daily Target Goal Card
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Today's Listening Goal")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(Theme.textDark)
                                    Text("Target: \(stats.dailyTargetMinutes) minutes / day")
                                        .font(.system(size: 13))
                                        .foregroundColor(Theme.textMuted)
                                }

                                Spacer()

                                Button {
                                    showingGoalPicker = true
                                } label: {
                                    Text("Edit Goal")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(Theme.brandGreen)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Theme.brandGreen.opacity(0.15))
                                        .clipShape(Capsule())
                                }
                            }

                            // Progress Bar
                            let currentDayMins = todayMinutes
                            let ratio = min(1.0, Double(currentDayMins) / Double(max(1, stats.dailyTargetMinutes)))

                            VStack(spacing: 6) {
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        Capsule()
                                            .fill(Theme.surfaceSubtle)
                                            .frame(height: 10)

                                        Capsule()
                                            .fill(Theme.brandGreen)
                                            .frame(width: CGFloat(ratio) * geo.size.width, height: 10)
                                    }
                                }
                                .frame(height: 10)

                                HStack {
                                    Text("\(currentDayMins) mins completed")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(Theme.brandGreen)
                                    Spacer()
                                    Text("\(max(0, stats.dailyTargetMinutes - currentDayMins)) mins remaining")
                                        .font(.system(size: 12))
                                        .foregroundColor(Theme.textMuted)
                                }
                            }
                        }
                        .padding(18)
                        .background(Theme.surfaceWhite)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Theme.cardBorder, lineWidth: 1)
                        )
                        .padding(.horizontal, 20)

                        // Weekly Listening Bar Chart
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Weekly Listening Activity")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Theme.textDark)

                            HStack(alignment: .bottom, spacing: 12) {
                                let minutes = weekMinutes
                                let maxMins = max(minutes.max() ?? 0, 30)
                                ForEach(0..<7, id: \.self) { idx in
                                    let value = minutes.indices.contains(idx) ? minutes[idx] : 0
                                    let barHeight = CGFloat(value) / CGFloat(maxMins) * 110.0
                                    let isToday = idx == currentWeekdayIndex

                                    VStack(spacing: 6) {
                                        Text("\(value)m")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(isToday ? Theme.brandGreen : Theme.textMuted)

                                        ZStack(alignment: .bottom) {
                                            Capsule()
                                                .fill(Theme.surfaceSubtle)
                                                .frame(width: 22, height: 110)

                                            Capsule()
                                                .fill(isToday ? AnyShapeStyle(Theme.brandGreen) : AnyShapeStyle(Theme.textMuted.opacity(0.35)))
                                                .frame(width: 22, height: max(barHeight, value > 0 ? 6 : 0))
                                        }

                                        Text(weekDays[idx])
                                            .font(.system(size: 11, weight: isToday ? .bold : .medium))
                                            .foregroundColor(isToday ? Theme.brandGreen : Theme.textMuted)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }
                            .padding(.top, 4)
                        }
                        .padding(18)
                        .background(Theme.surfaceWhite)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Theme.cardBorder, lineWidth: 1)
                        )
                        .padding(.horizontal, 20)

                        // Milestone Achievements
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Milestones & Badges")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Theme.textDark)

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                BadgeItem(title: "Night Owl", subtitle: "Listened past 10 PM", icon: "moon.stars.fill", color: Color.purple, isUnlocked: stats.totalMinutesListened > 0)
                                BadgeItem(title: "10-Hour Club", subtitle: "Total 600 mins", icon: "crown.fill", color: Color.orange, isUnlocked: stats.totalMinutesListened >= 600)
                                BadgeItem(title: "Polymath", subtitle: "3 different genres", icon: "brain.head.profile", color: Theme.brandGreen, isUnlocked: false)
                                BadgeItem(title: "Marathoner", subtitle: "60 mins in one day", icon: "figure.run", color: Color.blue, isUnlocked: (stats.dailyHistory.values.max() ?? 0) >= 60)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 160)
                    }
                }
            }
            .navigationTitle("Activity & Habits")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                stats = StorageService.shared.loadStats()
            }
            .confirmationDialog("Choose Daily Listening Goal", isPresented: $showingGoalPicker, titleVisibility: .visible) {
                Button("15 minutes / day") { updateGoal(15) }
                Button("30 minutes / day") { updateGoal(30) }
                Button("45 minutes / day") { updateGoal(45) }
                Button("60 minutes / day") { updateGoal(60) }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private var todayMinutes: Int {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return stats.dailyHistory[formatter.string(from: Date())] ?? 0
    }

    private var currentWeekdayIndex: Int {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return (weekday + 5) % 7
    }

    private var weekMinutes: [Int] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = Date()
        let daysFromMonday = currentWeekdayIndex
        guard let monday = calendar.date(byAdding: .day, value: -daysFromMonday, to: today) else {
            return Array(repeating: 0, count: 7)
        }
        return (0..<7).map { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: monday) else { return 0 }
            return stats.dailyHistory[formatter.string(from: day)] ?? 0
        }
    }

    private func updateGoal(_ mins: Int) {
        stats.dailyTargetMinutes = mins
        StorageService.shared.saveStats(stats)
    }
}

private struct BadgeItem: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let isUnlocked: Bool

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? color.opacity(0.18) : Theme.surfaceSubtle)
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(isUnlocked ? color : Theme.textMuted)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(isUnlocked ? Theme.textDark : Theme.textMuted)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textMuted)
                    .lineLimit(1)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surfaceWhite)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Theme.cardBorder, lineWidth: 1)
        )
        .opacity(isUnlocked ? 1.0 : 0.6)
    }
}
