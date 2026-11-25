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
                MangaTheme.surface.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack(spacing: 12) {
                            Button {
                                AppNavigationState.shared.openSidebar()
                            } label: {
                                Image(systemName: "line.3.horizontal")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(MangaTheme.ink)
                                    .frame(width: 44, height: 44)
                                    .background(MangaTheme.surfaceLow)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(MangaTheme.hairline, lineWidth: 1))
                            }
                            .accessibilityLabel("Open Menu")

                            VStack(alignment: .leading, spacing: 1) {
                                Text("読書記録 / HABITS")
                                    .font(.system(size: 10, weight: .bold))
                                    .tracking(1.2)
                                    .foregroundStyle(MangaTheme.vermilion)
                                Text("Reading Habits")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundStyle(MangaTheme.ink)
                            }

                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                        paperCard {
                            HStack(spacing: 16) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 52, height: 52)
                                    .background(MangaTheme.vermilion)
                                    .clipShape(Circle())

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(stats.streakDays) day streak")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundStyle(MangaTheme.ink)
                                    Text(stats.streakDays == 0 ? "Listen today to start your streak." : "You've listened on consecutive days.")
                                        .font(.system(size: 13))
                                        .foregroundStyle(MangaTheme.secondary)
                                        .lineLimit(2)
                                }
                            }
                        }

                        paperCard {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Today")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(Theme.textDark)
                                    Text("\(stats.dailyTargetMinutes) minutes")
                                        .font(.system(size: 13))
                                        .foregroundStyle(Theme.textMuted)
                                }
                                Spacer()
                                Button {
                                    showingGoalPicker = true
                                } label: {
                                    Text("Edit")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(Theme.onAccent)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Theme.ember)
                                        .clipShape(Capsule())
                                }
                            }

                            let currentDayMins = todayMinutes
                            let ratio = min(1.0, Double(currentDayMins) / Double(max(1, stats.dailyTargetMinutes)))

                            VStack(spacing: 6) {
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        Capsule().fill(Theme.stone.opacity(0.45)).frame(height: 6)
                                        Capsule().fill(Theme.ember).frame(width: max(4, CGFloat(ratio) * geo.size.width), height: 6)
                                    }
                                }
                                .frame(height: 6)

                                HStack {
                                    Text("\(currentDayMins) min")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(Theme.ember)
                                    Spacer()
                                    Text("\(max(0, stats.dailyTargetMinutes - currentDayMins)) min left")
                                        .font(.system(size: 12))
                                        .foregroundStyle(Theme.textMuted)
                                }
                            }
                        }

                        paperCard {
                            Text("This week")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Theme.textDark)

                            HStack(alignment: .bottom, spacing: 12) {
                                let minutes = weekMinutes
                                let maxMins = max(minutes.max() ?? 0, 30)
                                ForEach(0..<7, id: \.self) { idx in
                                    let value = minutes.indices.contains(idx) ? minutes[idx] : 0
                                    let barHeight = CGFloat(value) / CGFloat(maxMins) * 110.0
                                    let isToday = idx == currentWeekdayIndex

                                    VStack(spacing: 6) {
                                        Text("\(value)")
                                            .font(.system(size: 10, weight: .semibold))
                                            .foregroundStyle(isToday ? Theme.ember : Theme.textMuted)

                                        ZStack(alignment: .bottom) {
                                            Capsule()
                                                .fill(Theme.stone.opacity(0.35))
                                                .frame(width: 18, height: 110)
                                            Capsule()
                                                .fill(isToday ? Theme.ember : Theme.charcoal.opacity(0.45))
                                                .frame(width: 18, height: max(barHeight, value > 0 ? 6 : 0))
                                        }

                                        Text(weekDays[idx])
                                            .font(.system(size: 11, weight: isToday ? .bold : .medium))
                                            .foregroundStyle(isToday ? Theme.ember : Theme.textMuted)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Milestones")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(Theme.textDark)
                                .padding(.horizontal, 20)

                            VStack(spacing: 10) {
                                BadgeItem(title: "Night Owl", subtitle: "Listened past 10 PM", icon: "moon.stars.fill", color: Theme.charcoal, isUnlocked: stats.totalMinutesListened > 0)
                                BadgeItem(title: "10-Hour Club", subtitle: "600 minutes listened", icon: "crown.fill", color: Theme.ember, isUnlocked: stats.totalMinutesListened >= 600)
                                BadgeItem(title: "Polymath", subtitle: "3 different genres", icon: "books.vertical.fill", color: Theme.ink, isUnlocked: false)
                                BadgeItem(title: "Marathoner", subtitle: "60 minutes in one day", icon: "figure.run", color: Theme.emberDeep, isUnlocked: (stats.dailyHistory.values.max() ?? 0) >= 60)
                            }
                            .padding(.horizontal, 20)
                        }

                        if !playerService.bookmarks.isEmpty {
                            Text("\(playerService.bookmarks.count) bookmarks saved")
                                .font(.system(size: 13))
                                .foregroundStyle(Theme.textMuted)
                                .padding(.horizontal, 20)
                        }

                        Spacer(minLength: 150)
                    }
                }
            }
            .navigationBarHidden(true)
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

    private func paperCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MangaTheme.surfaceLow)
        .clipShape(RoundedRectangle(cornerRadius: MangaTheme.cardRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: MangaTheme.cardRadius).stroke(MangaTheme.hairline, lineWidth: 1))
        .shadow(color: MangaTheme.cardShadow, radius: 8, x: 0, y: 3)
        .padding(.horizontal, 20)
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
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(isUnlocked ? .white : MangaTheme.secondary)
                .frame(width: 40, height: 40)
                .background(isUnlocked ? color : MangaTheme.surfaceContainer)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(isUnlocked ? MangaTheme.ink : MangaTheme.secondary)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(MangaTheme.secondary)
                    .lineLimit(1)
            }
            Spacer()
            if isUnlocked {
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(MangaTheme.vermilion)
            }
        }
        .padding(12)
        .background(MangaTheme.surfaceLow)
        .clipShape(RoundedRectangle(cornerRadius: MangaTheme.cardRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: MangaTheme.cardRadius).stroke(MangaTheme.hairline, lineWidth: 1))
        .shadow(color: MangaTheme.cardShadow, radius: 8, x: 0, y: 3)
    }
}
