import SwiftUI
import UniformTypeIdentifiers

public enum MangaLibraryFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case reading = "Reading"
    case planToRead = "Plan to Read"
    case completed = "Completed"
    case downloads = "Downloads"

    public var id: String { rawValue }
}

public struct MangaLibraryScreenView: View {
    @Bindable var library = MangaLibrary.shared
    @Bindable var newChapters = NewChapterTracker.shared
    @State private var selectedFilter: MangaLibraryFilter = .reading
    @State private var selectedFormat: String = "Manga & Manhwa"
    @State private var isAscendingSort = false
    @State private var isRefreshing = false
    @State private var showingImporter = false
    @State private var importErrorMessage: String?

    private let formats = ["Manga & Manhwa", "Light Novels", "Audiobooks"]

    public init() {}

    private var displaySeries: [MangaSeries] {
        var base: [MangaSeries] = []
        let allAvailable = MangaDexService.curatedCatalog + MangaDexService.webtoonCatalog + MangaDexService.vintageArchiveCatalog
        switch selectedFilter {
        case .all:
            base = library.opened + library.imported.map { $0.series }
            if base.isEmpty { base = allAvailable }
        case .reading:
            base = library.opened.isEmpty ? Array(allAvailable.prefix(6)) : library.opened
        case .planToRead:
            base = allAvailable.filter { library.isBookmarked($0.id) }
            if base.isEmpty { base = Array(allAvailable.suffix(4)) }
        case .completed:
            base = allAvailable.filter { $0.status == "COMPLETED" }
        case .downloads:
            base = library.imported.map { $0.series }
            if base.isEmpty {
                base = allAvailable.filter { s in
                    library.downloadedChapterIds.contains { $0.hasPrefix(s.id) }
                }
            }
        }

        if selectedFormat == "Light Novels" {
            let filtered = base.filter { $0.genres?.contains("Novel") ?? false || $0.genres?.contains("Light Novel") ?? false }
            base = filtered.isEmpty ? base : filtered
        } else if selectedFormat == "Audiobooks" {
            let filtered = base.filter { $0.audioDramaAvailable == true }
            base = filtered.isEmpty ? base : filtered
        }

        if isAscendingSort {
            return base.sorted { $0.title < $1.title }
        } else {
            return base.sorted { ($0.rating ?? 0) > ($1.rating ?? 0) }
        }
    }

    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                // Header Row
                HStack(alignment: .firstTextBaseline) {
                    HStack(spacing: 8) {
                        Text("My Library")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(MangaTheme.ink)
                        Text("\(displaySeries.count) titles")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(MangaTheme.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(MangaTheme.surfaceContainer, in: Capsule())
                    }

                    Spacer()

                    HStack(spacing: 8) {
                        Button {
                            showingImporter = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(MangaTheme.ink)
                                .frame(width: 36, height: 36)
                                .background(MangaTheme.surfaceLow)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(MangaTheme.hairline, lineWidth: 1))
                        }
                        .accessibilityLabel("Import CBZ/Manga")

                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isAscendingSort.toggle()
                            }
                        } label: {
                            Image(systemName: isAscendingSort ? "arrow.up" : "arrow.down")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(isAscendingSort ? MangaTheme.vermilion : MangaTheme.ink)
                                .frame(width: 36, height: 36)
                                .background(MangaTheme.surfaceLow)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(MangaTheme.hairline, lineWidth: 1))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)

                // Category Filter Pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(MangaLibraryFilter.allCases) { filter in
                            let isSel = selectedFilter == filter
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    selectedFilter = filter
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    if isSel {
                                        Circle()
                                            .fill(Color.white)
                                            .frame(width: 5, height: 5)
                                    }
                                    Text(filter.rawValue)
                                        .font(.system(size: 13, weight: isSel ? .bold : .medium))
                                        .foregroundStyle(isSel ? .white : MangaTheme.ink)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 9)
                                .background(isSel ? MangaTheme.vermilion : MangaTheme.surfaceLow)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule().stroke(isSel ? Color.clear : MangaTheme.hairline, lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }

                // Format Sub-Pills & Sync Status Bar
                HStack(spacing: 8) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(formats, id: \.self) { fmt in
                                let isSel = selectedFormat == fmt
                                Button {
                                    selectedFormat = fmt
                                } label: {
                                    Text(fmt)
                                        .font(.system(size: 12, weight: isSel ? .bold : .medium))
                                        .foregroundStyle(isSel ? MangaTheme.ink : MangaTheme.secondary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(isSel ? MangaTheme.surfaceContainer : MangaTheme.surfaceLow)
                                        .clipShape(Capsule())
                                        .overlay(Capsule().stroke(MangaTheme.hairline, lineWidth: 1))
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)

                // Sync Notice Banner
                HStack(spacing: 8) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(MangaTheme.vermilion)
                    Text("Updated 10m ago • 4 new chapters available")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(MangaTheme.inkVariant)
                    Spacer()
                    Button("Refresh") {
                        Task {
                            isRefreshing = true
                            _ = try? await MangaDexService.shared.popular()
                            isRefreshing = false
                        }
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(MangaTheme.vermilion)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(MangaTheme.surfaceContainer.opacity(0.8))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(MangaTheme.hairline, lineWidth: 1))
                .padding(.horizontal, 16)

                // 14-Day Reading Streak Banner (Moments of Delight)
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(MangaTheme.surfaceContainer)
                            .frame(width: 44, height: 44)
                        Image(systemName: "flame.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(MangaTheme.vermilion)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text("\(library.streakDays)-Day Reading Streak")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(MangaTheme.ink)
                            Spacer()
                            Text("80%")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(MangaTheme.vermilion)
                        }

                        Text("\(library.streakMinutesToday) mins today • Goal: \(library.streakMinutesGoal) mins")
                            .font(.system(size: 12))
                            .foregroundStyle(MangaTheme.secondary)

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(MangaTheme.surfaceContainer)
                                    .frame(height: 5)
                                Capsule()
                                    .fill(MangaTheme.vermilion)
                                    .frame(width: geo.size.width * 0.8, height: 5)
                            }
                        }
                        .frame(height: 5)
                        .padding(.top, 2)
                    }
                }
                .padding(14)
                .background(MangaTheme.surfaceLow)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(MangaTheme.hairline, lineWidth: 1))
                .padding(.horizontal, 16)

                // Content Grid: 2 Columns with 2:3 Cards
                if displaySeries.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "book.pages")
                            .font(.system(size: 40))
                            .foregroundStyle(MangaTheme.secondary.opacity(0.6))
                            .padding(.top, 40)
                        Text("No Manga in this category")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(MangaTheme.ink)
                        Text("Explore the catalog to bookmark or import your favorite CBZ manga.")
                            .font(.system(size: 13))
                            .foregroundStyle(MangaTheme.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                } else {
                    LazyVGrid(
                        columns: DuoLayout.adaptiveCardColumns,
                        spacing: 18
                    ) {
                        ForEach(displaySeries) { series in
                            NavigationLink(destination: MangaDetailView(series: series, localChapters: library.imported.first { $0.id == series.id }?.chapters)) {
                                VStack(alignment: .leading, spacing: 6) {
                                    ZStack(alignment: .topTrailing) {
                                        MangaCoverCard(
                                            series: series,
                                            progress: nil,
                                            badgeText: series.genres?.first ?? "MANGA"
                                        )
                                        .frame(maxWidth: .infinity)

                                        // New chapters badge
                                        if case let unread = newChapters.unread(series.id), unread > 0 {
                                            Text("\(unread) new")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundStyle(.white)
                                                .padding(.horizontal, 7)
                                                .padding(.vertical, 3)
                                                .background(MangaTheme.vermilion, in: Capsule())
                                                .padding(6)
                                        }
                                    }

                                    Text(series.title)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(MangaTheme.ink)
                                        .lineLimit(1)

                                    HStack {
                                        Text(series.lastReadChapter ?? "Not started")
                                            .font(.system(size: 12))
                                            .foregroundStyle(MangaTheme.secondary)
                                        Spacer()
                                        if series.isLocal {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 12))
                                                .foregroundStyle(MangaTheme.vermilion)
                                        } else {
                                            Text("Read next")
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundStyle(MangaTheme.vermilion)
                                        }
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .task { await newChapters.refresh(series) }
                        }
                    }
                    .padding(.horizontal, 16)
                }

                Spacer(minLength: 60)
            }
            .padding(.vertical, 8)
        }
        .background(MangaTheme.surface)
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [
                UTType(filenameExtension: "cbz") ?? .data,
                UTType.zip
            ]
        ) { result in
            do {
                let url = try result.get()
                let stored = try CBZImporter.importFile(at: url)
                library.add(stored)
            } catch {
                importErrorMessage = error.localizedDescription
            }
        }
    }
}

