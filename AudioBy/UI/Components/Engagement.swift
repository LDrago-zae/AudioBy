import SwiftUI
import UserNotifications

// MARK: - Daily reminder

@Observable
public final class ReminderService {
    public static let shared = ReminderService()
    public private(set) var enabled: Bool
    public var hour: Int { didSet { UserDefaults.standard.set(hour, forKey: "AudioBy.reminderHour"); if enabled { schedule() } } }

    private init() {
        enabled = UserDefaults.standard.bool(forKey: "AudioBy.reminderOn")
        let h = UserDefaults.standard.object(forKey: "AudioBy.reminderHour") as? Int
        hour = h ?? 20
    }

    public func toggle() async {
        if enabled {
            enabled = false
            UserDefaults.standard.set(false, forKey: "AudioBy.reminderOn")
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["audioby.daily"])
            return
        }
        let granted = (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        guard granted else { return }
        enabled = true
        UserDefaults.standard.set(true, forKey: "AudioBy.reminderOn")
        schedule()
    }

    private func schedule() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["audioby.daily"])
        let content = UNMutableNotificationContent()
        content.title = "Your story is waiting"
        content.body = "A few minutes today keeps your streak alive."
        content.sound = .default
        var comps = DateComponents(); comps.hour = hour; comps.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        center.add(UNNotificationRequest(identifier: "audioby.daily", content: content, trigger: trigger))
    }
}

// MARK: - Weekly activity + streak rewards

public struct WeeklyActivityCard: View {
    private let stats = StorageService.shared.loadStats()
    public init() {}

    private var days: [(label: String, minutes: Int, isToday: Bool)] {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        let cal = Calendar.current
        let short = DateFormatter(); short.dateFormat = "EEEEE"
        return (0..<7).reversed().map { offset in
            let d = cal.date(byAdding: .day, value: -offset, to: Date()) ?? Date()
            return (short.string(from: d), stats.dailyHistory[f.string(from: d)] ?? 0, offset == 0)
        }
    }

    public var body: some View {
        let data = days
        let peak = max(data.map(\.minutes).max() ?? 0, stats.dailyTargetMinutes, 1)
        let total = data.map(\.minutes).reduce(0, +)
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("This week")
                        .font(.system(size: 15, weight: .bold)).foregroundStyle(MangaTheme.ink)
                    Text("\(total) min listened")
                        .font(.system(size: 12)).foregroundStyle(MangaTheme.secondary)
                }
                Spacer()
            }
            HStack(alignment: .bottom, spacing: 10) {
                ForEach(Array(data.enumerated()), id: \.offset) { _, d in
                    VStack(spacing: 6) {
                        ZStack(alignment: .bottom) {
                            Capsule().fill(MangaTheme.surfaceHighest).frame(height: 70)
                            Capsule()
                                .fill(d.isToday ? MangaTheme.vermilion : MangaTheme.vermilion.opacity(0.55))
                                .frame(height: max(CGFloat(d.minutes) / CGFloat(peak) * 70, d.minutes > 0 ? 6 : 0))
                        }
                        .frame(maxWidth: .infinity)
                        Text(d.label)
                            .font(.system(size: 10, weight: d.isToday ? .bold : .medium))
                            .foregroundStyle(d.isToday ? MangaTheme.ink : MangaTheme.secondary)
                    }
                }
            }
        }
        .padding(16)
        .background(MangaTheme.surfaceLow)
        .clipShape(RoundedRectangle(cornerRadius: MangaTheme.cardRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: MangaTheme.cardRadius, style: .continuous).stroke(MangaTheme.hairline, lineWidth: 1))
        .padding(.horizontal, 20)
    }
}

public struct StreakRewardsCard: View {
    private let streak = StorageService.shared.loadStats().streakDays
    private let tiers: [(days: Int, name: String, icon: String)] = [
        (3, "Spark", "sparkle"), (7, "Week", "flame.fill"), (14, "Fortnight", "moon.stars.fill"),
        (30, "Month", "crown.fill"), (100, "Legend", "trophy.fill")
    ]
    public init() {}

    public var body: some View {
        let next = tiers.first { streak < $0.days }
        VStack(alignment: .leading, spacing: 12) {
            Text(next.map { "\($0.days - streak) more day\($0.days - streak == 1 ? "" : "s") to \($0.name)" } ?? "Every badge unlocked")
                .font(.system(size: 15, weight: .bold)).foregroundStyle(MangaTheme.ink)
            HStack(spacing: 10) {
                ForEach(tiers, id: \.days) { t in
                    let unlocked = streak >= t.days
                    VStack(spacing: 6) {
                        Image(systemName: t.icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(unlocked ? .white : MangaTheme.secondary)
                            .frame(width: 46, height: 46)
                            .background(unlocked ? MangaTheme.vermilion : MangaTheme.surfaceHighest, in: Circle())
                        Text("\(t.days)d")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(unlocked ? MangaTheme.ink : MangaTheme.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(16)
        .background(MangaTheme.surfaceLow)
        .clipShape(RoundedRectangle(cornerRadius: MangaTheme.cardRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: MangaTheme.cardRadius, style: .continuous).stroke(MangaTheme.hairline, lineWidth: 1))
        .padding(.horizontal, 20)
    }
}

// MARK: - Day / night quick toggle

public struct ThemeToggleButton: View {
    @AppStorage("isDarkMode") private var isDarkMode: Bool = true
    public init() {}
    public var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.3)) { isDarkMode.toggle() }
        } label: {
            Image(systemName: isDarkMode ? "sun.max.fill" : "moon.stars.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(MangaTheme.ink)
                .frame(width: 38, height: 38)
                .background(MangaTheme.surfaceLow)
                .clipShape(Circle())
                .overlay(Circle().stroke(MangaTheme.hairline, lineWidth: 1))
        }
        .accessibilityLabel(isDarkMode ? "Switch to day mode" : "Switch to night mode")
    }
}

// MARK: - Reviews

public struct LocalReview: Codable, Identifiable, Hashable {
    public var id = UUID()
    public var bookId: String
    public var userName: String
    public var rating: Int
    public var title: String
    public var comment: String
    public var date: Date
}

@Observable
public final class ReviewStore {
    public static let shared = ReviewStore()
    public private(set) var all: [LocalReview] = []
    private let key = "AudioBy.localReviews"

    private init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([LocalReview].self, from: data) { all = decoded }
    }

    public func reviews(for bookId: String) -> [LocalReview] {
        all.filter { $0.bookId == bookId }.sorted { $0.date > $1.date }
    }

    public func add(_ r: LocalReview) {
        all.append(r)
        if let data = try? JSONEncoder().encode(all) { UserDefaults.standard.set(data, forKey: key) }
    }
}

public struct StarRow: View {
    public let rating: Int
    public init(_ rating: Int) { self.rating = rating }
    public var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { i in
                Image(systemName: i <= rating ? "star.fill" : "star")
                    .font(.system(size: 10)).foregroundStyle(MangaTheme.vermilion)
            }
        }
    }
}

public struct ReviewsCarousel: View {
    let bookId: String
    let publishedReviews: [BookReview]
    @Bindable private var store = ReviewStore.shared
    @State private var writing = false
    @Bindable private var auth = AuthService.shared

    public init(bookId: String, publishedReviews: [BookReview]) {
        self.bookId = bookId
        self.publishedReviews = publishedReviews
    }

    public var body: some View {
        let mine = store.reviews(for: bookId)
        VStack(alignment: .leading, spacing: 12) {
            if mine.isEmpty && publishedReviews.isEmpty {
                Text("No reviews yet. Be the first.")
                    .font(.system(size: 13)).foregroundStyle(MangaTheme.secondary)
                    .padding(.horizontal, 20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(mine) { r in
                            card(name: r.userName, stars: r.rating, title: r.title, text: r.comment,
                                 date: r.date.formatted(date: .abbreviated, time: .omitted))
                        }
                        ForEach(publishedReviews) { r in
                            card(name: r.userName, stars: Int(r.rating.rounded()), title: "", text: r.comment, date: r.dateString)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            Button { writing = true } label: {
                Text("Leave a review")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(MangaTheme.ink)
                    .frame(maxWidth: .infinity).frame(height: 46)
                    .background(MangaTheme.surfaceLow, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(MangaTheme.hairline, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
        }
        .sheet(isPresented: $writing) {
            LeaveReviewSheet(bookId: bookId, name: auth.displayName.isEmpty ? "Listener" : auth.displayName)
                .presentationDetents([.medium])
        }
    }

    private func card(name: String, stars: Int, title: String, text: String, date: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            StarRow(stars)
            HStack(spacing: 8) {
                Text(String(name.prefix(1)).uppercased())
                    .font(.system(size: 12, weight: .bold)).foregroundStyle(.white)
                    .frame(width: 28, height: 28).background(MangaTheme.vermilion, in: Circle())
                VStack(alignment: .leading, spacing: 0) {
                    Text(name).font(.system(size: 12, weight: .bold)).foregroundStyle(MangaTheme.ink)
                    Text(date).font(.system(size: 10)).foregroundStyle(MangaTheme.secondary)
                }
            }
            if !title.isEmpty {
                Text(title).font(.system(size: 14, weight: .bold)).foregroundStyle(MangaTheme.ink)
            }
            Text(text).font(.system(size: 12)).foregroundStyle(MangaTheme.secondary)
                .lineSpacing(3).lineLimit(5)
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(width: 270, height: 180, alignment: .topLeading)
        .background(MangaTheme.surfaceLow)
        .clipShape(RoundedRectangle(cornerRadius: MangaTheme.cardRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: MangaTheme.cardRadius, style: .continuous).stroke(MangaTheme.hairline, lineWidth: 1))
    }
}

struct LeaveReviewSheet: View {
    let bookId: String
    let name: String
    @Environment(\.dismiss) private var dismiss
    @State private var rating = 5
    @State private var title = ""
    @State private var comment = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Your review").font(.system(size: 18, weight: .bold)).foregroundStyle(MangaTheme.ink)
            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { i in
                    Button { rating = i } label: {
                        Image(systemName: i <= rating ? "star.fill" : "star")
                            .font(.system(size: 26)).foregroundStyle(MangaTheme.vermilion)
                    }.buttonStyle(.plain)
                }
            }
            TextField("Headline", text: $title).textFieldStyle(.roundedBorder)
            TextField("What did you think?", text: $comment, axis: .vertical)
                .lineLimit(3...5).textFieldStyle(.roundedBorder)
            Button {
                ReviewStore.shared.add(LocalReview(bookId: bookId, userName: name, rating: rating,
                                                   title: title, comment: comment, date: Date()))
                dismiss()
            } label: {
                Text("Post review").font(.system(size: 15, weight: .bold)).foregroundStyle(.white)
                    .frame(maxWidth: .infinity).frame(height: 48)
                    .background(MangaTheme.vermilion, in: RoundedRectangle(cornerRadius: 14))
            }
            .disabled(comment.trimmingCharacters(in: .whitespaces).isEmpty)
            Spacer()
        }
        .padding(20)
        .background(MangaTheme.surface.ignoresSafeArea())
    }
}

// MARK: - Detail stats strip

public struct BookStatsStrip: View {
    let rating: Double
    let reviews: Int
    let duration: String
    public init(rating: Double, reviews: Int, duration: String) {
        self.rating = rating; self.reviews = reviews; self.duration = duration
    }
    public var body: some View {
        HStack(spacing: 0) {
            stat(value: rating > 0 ? String(format: "%.1f", rating) : "New", label: "Rating", star: rating > 0)
            Divider().frame(height: 28)
            stat(value: "\(reviews)", label: "Reviews", star: false)
            Divider().frame(height: 28)
            stat(value: duration, label: "Duration", star: false)
        }
        .padding(.vertical, 12)
        .background(MangaTheme.surfaceLow)
        .clipShape(RoundedRectangle(cornerRadius: MangaTheme.cardRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: MangaTheme.cardRadius, style: .continuous).stroke(MangaTheme.hairline, lineWidth: 1))
        .padding(.horizontal, 20)
    }
    private func stat(value: String, label: String, star: Bool) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 3) {
                if star { Image(systemName: "star.fill").font(.system(size: 11)).foregroundStyle(MangaTheme.vermilion) }
                Text(value).font(.system(size: 15, weight: .bold)).foregroundStyle(MangaTheme.ink)
            }
            Text(label).font(.system(size: 11)).foregroundStyle(MangaTheme.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - New chapter tracking

@Observable
public final class NewChapterTracker {
    public static let shared = NewChapterTracker()
    private var latest: [String: Int] = [:]
    private var seen: [String: Int]
    private let key = "AudioBy.seenChapterCounts"

    private init() {
        seen = (UserDefaults.standard.dictionary(forKey: key) as? [String: Int]) ?? [:]
    }

    /// Fetches the current English chapter count. The first sighting becomes the baseline, so only later releases show as new.
    public func refresh(_ series: MangaSeries) async {
        guard let chapters = try? await MangaDexService.shared.chapters(for: series.id), !chapters.isEmpty else { return }
        latest[series.id] = chapters.count
        if seen[series.id] == nil { persist(series.id, chapters.count) }
    }

    public func unread(_ id: String) -> Int {
        max((latest[id] ?? 0) - (seen[id] ?? latest[id] ?? 0), 0)
    }

    public func markSeen(_ id: String) {
        if let n = latest[id] { persist(id, n) }
    }

    private func persist(_ id: String, _ n: Int) {
        seen[id] = n
        UserDefaults.standard.set(seen, forKey: key)
    }
}

// MARK: - Plus upsell + reminder time

public struct PlusUpsellRow: View {
    @Binding var showingPaywall: Bool
    public init(showingPaywall: Binding<Bool>) { _showingPaywall = showingPaywall }
    public var body: some View {
        if !EntitlementService.shared.isPlus {
            Button { showingPaywall = true } label: {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles").foregroundStyle(MangaTheme.vermilion)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Unlock with Plus").font(.system(size: 14, weight: .bold)).foregroundStyle(MangaTheme.ink)
                        Text("Unlimited downloads, scenes and more").font(.system(size: 11)).foregroundStyle(MangaTheme.secondary)
                    }
                    Spacer()
                    Text("Upgrade").font(.system(size: 12, weight: .bold)).foregroundStyle(.white)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(MangaTheme.vermilion, in: Capsule())
                }
                .padding(14)
                .background(MangaTheme.surfaceLow, in: RoundedRectangle(cornerRadius: MangaTheme.cardRadius, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: MangaTheme.cardRadius, style: .continuous).stroke(MangaTheme.hairline, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
        }
    }
}

public struct ReminderTimeMenu: View {
    @Bindable var reminders = ReminderService.shared
    public init() {}
    public var body: some View {
        Picker("Reminder time", selection: $reminders.hour) {
            ForEach(6..<24, id: \.self) { h in
                Text(Calendar.current.date(from: DateComponents(hour: h)).map { $0.formatted(date: .omitted, time: .shortened) } ?? "\(h):00").tag(h)
            }
        }
    }
}
