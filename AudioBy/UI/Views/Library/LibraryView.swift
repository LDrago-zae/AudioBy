import SwiftUI

/// Japanese editorial Library View for Audiobooks & Novels.
/// Directly implements the Komorebi design system matching stitch_reference/my_library.
public enum LibraryShelf: String, CaseIterable, Identifiable {
    case all = "All"
    case inProgress = "Listening"
    case saved = "Saved"
    case downloaded = "Downloaded"
    case finished = "Finished"
    case imported = "Imported"

    public var id: String { rawValue }
}

public enum LibraryLayoutMode {
    case grid
    case list
}

public struct LibraryView: View {
    @Bindable var repository = AudiobookRepository.shared
    @Bindable var playerService = AudioPlayerService.shared
    @Bindable var downloadManager = DownloadManager.shared
    @Bindable var nav = AppNavigationState.shared

    @State private var selectedShelf: LibraryShelf = .all
    @State private var layoutMode: LibraryLayoutMode = .grid
    @State private var selectedFormat: String = "All Formats"
    @State private var showingClearConfirmation = false
    @State private var showingImporter = false
    @State private var showingPaywall = false

    private let formatOptions = ["All Formats", "Audiobooks", "Light Novels", "Audio Dramas"]

    public init() {}

    private func applyRequestedShelf() {
        if let shelf = nav.requestedLibraryShelf {
            selectedShelf = shelf
            nav.requestedLibraryShelf = nil
        }
    }

    private var currentBooks: [Audiobook] {
        let base: [Audiobook]
        switch selectedShelf {
        case .all:
            base = repository.audiobooks
        case .inProgress:
            base = repository.continueListeningBooks
        case .saved:
            base = repository.favoriteBooks
        case .downloaded:
            base = repository.downloadedBooks
        case .finished:
            base = repository.finishedBooks
        case .imported:
            base = repository.importedBooks
        }

        if selectedFormat == "Light Novels" {
            return base.filter { $0.gutenbergId != nil }
        } else if selectedFormat == "Audio Dramas" {
            return base.filter { $0.listenCount > 500 }
        }
        return base
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                MangaTheme.surface.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        // 1. Top Bar with Hamburger & Tools
                        libraryTopBar

                        // 2. Category Filter Pills (All, Listening, Saved, etc.)
                        categoryFilterPills

                        // 3. Format Sub-Bar (All Formats, Audiobooks, Novels)
                        formatSubBar

                        // 4. Cloud Sync Notice Banner
                        cloudSyncBanner

                        // 5. 14-Day Reading Streak Delight Card
                        KomorebiStreakWidget(
                            streakDays: 14,
                            minutesToday: 48,
                            goalMinutes: 60
                        )

                        // 6. Offline Storage Banner (when viewing downloads)
                        if selectedShelf == .downloaded {
                            offlineStorageBanner
                        }

                        // 7. Books Showcase (Grid or List)
                        booksSection

                        // 8. Saved Bookmarks & Annotations
                        if !playerService.bookmarks.isEmpty {
                            savedBookmarksSection
                        }

                        Spacer(minLength: 160)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear { applyRequestedShelf() }
            .onChange(of: nav.requestedLibraryShelf) { _, _ in
                applyRequestedShelf()
            }
            .modifier(PDFImportPresenter(isPresented: $showingImporter, showingPaywall: $showingPaywall))
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .confirmationDialog("Clear All Offline Downloads?", isPresented: $showingClearConfirmation, titleVisibility: .visible) {
                Button("Delete All Downloads", role: .destructive) {
                    downloadManager.clearAllCache()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will remove all downloaded audiobooks from your device to free up storage space.")
            }
        }
    }

    // MARK: - 1. Top Bar
    private var libraryTopBar: some View {
        HStack(spacing: 12) {
            Button {
                nav.openSidebar()
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

            HStack(spacing: 8) {
                Text("My Library")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(MangaTheme.ink)

                Text("\(repository.audiobooks.count) titles")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(MangaTheme.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(MangaTheme.surfaceHigh)
                    .clipShape(Capsule())
            }

            Spacer()

            HStack(spacing: 8) {
                // Layout Toggle (Grid vs List)
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        layoutMode = (layoutMode == .grid) ? .list : .grid
                    }
                } label: {
                    Image(systemName: layoutMode == .grid ? "list.bullet" : "square.grid.2x2")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(MangaTheme.ink)
                        .frame(width: 38, height: 38)
                        .background(MangaTheme.surfaceLow)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(MangaTheme.hairline, lineWidth: 1))
                }

                // Import PDF / File Button
                Button {
                    showingImporter = true
                } label: {
                    Image(systemName: "doc.badge.plus")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(MangaTheme.vermilion)
                        .frame(width: 38, height: 38)
                        .background(MangaTheme.surfaceLow)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(MangaTheme.hairline, lineWidth: 1))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    // MARK: - 2. Category Filter Pills
    private var categoryFilterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(LibraryShelf.allCases) { shelf in
                    let isSel = selectedShelf == shelf
                    let count = shelfCount(shelf)
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedShelf = shelf
                        }
                    } label: {
                        HStack(spacing: 6) {
                            if isSel {
                                Circle()
                                    .fill(MangaTheme.vermilionFixed)
                                    .frame(width: 5, height: 5)
                            }
                            Text("\(shelf.rawValue) (\(count))")
                                .font(.system(size: 12, weight: isSel ? .bold : .medium))
                        }
                        .foregroundStyle(isSel ? .white : MangaTheme.ink)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(isSel ? MangaTheme.vermilion : MangaTheme.surfaceLow)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(isSel ? Color.clear : MangaTheme.hairline, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func shelfCount(_ shelf: LibraryShelf) -> Int {
        switch shelf {
        case .all: return repository.audiobooks.count
        case .inProgress: return repository.continueListeningBooks.count
        case .saved: return repository.favoriteBooks.count
        case .downloaded: return repository.downloadedBooks.count
        case .finished: return repository.finishedBooks.count
        case .imported: return repository.importedBooks.count
        }
    }

    // MARK: - 3. Format Sub-Bar
    private var formatSubBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(formatOptions, id: \.self) { format in
                    let isSel = selectedFormat == format
                    Button {
                        selectedFormat = format
                    } label: {
                        Text(format)
                            .font(.system(size: 11, weight: isSel ? .bold : .medium))
                            .foregroundStyle(isSel ? MangaTheme.ink : MangaTheme.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(isSel ? MangaTheme.surfaceHigh : MangaTheme.surfaceContainer)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - 4. Cloud Sync Banner
    private var cloudSyncBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 14))
                .foregroundStyle(MangaTheme.vermilion)

            Text("Cloud sync up to date • Library synchronized")
                .font(.system(size: 12))
                .foregroundStyle(MangaTheme.secondary)
                .lineLimit(1)

            Spacer()

            Button {
                Task { await repository.fetchRemoteAudiobooks() }
            } label: {
                Text("Refresh")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(MangaTheme.vermilion)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(MangaTheme.surfaceLow)
        .clipShape(RoundedRectangle(cornerRadius: MangaTheme.cardRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: MangaTheme.cardRadius).stroke(MangaTheme.hairline, lineWidth: 1))
        .padding(.horizontal, 20)
    }

    // MARK: - Offline Storage Banner
    private var offlineStorageBanner: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Offline Storage Usage")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(MangaTheme.ink)
                Text("\(downloadManager.formattedStorageUsed) used across \(downloadManager.downloadedBookIds.count) titles")
                    .font(.system(size: 11))
                    .foregroundStyle(MangaTheme.secondary)
            }

            Spacer()

            if !downloadManager.downloadedBookIds.isEmpty {
                Button {
                    showingClearConfirmation = true
                } label: {
                    Text("Clear All")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.red)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.red.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(14)
        .background(MangaTheme.surfaceLow)
        .clipShape(RoundedRectangle(cornerRadius: MangaTheme.cardRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: MangaTheme.cardRadius).stroke(MangaTheme.hairline, lineWidth: 1))
        .padding(.horizontal, 20)
    }

    // MARK: - 7. Books Section
    private var booksSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            if currentBooks.isEmpty {
                emptyLibraryPlaceholder
            } else if layoutMode == .grid {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 14),
                        GridItem(.flexible(), spacing: 14)
                    ],
                    spacing: 18
                ) {
                    ForEach(currentBooks) { book in
                        NavigationLink(destination: AudiobookDetailView(book: book)) {
                            KomorebiBookCard(book: book)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(currentBooks) { book in
                        NavigationLink(destination: AudiobookDetailView(book: book)) {
                            komorebiListRow(book: book)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }

            if selectedShelf == .all && !currentBooks.isEmpty {
                loadMoreFooter
            }
        }
    }

    /// Fires when scrolled to the end; fetches the next 20 titles.
    private var loadMoreFooter: some View {
        HStack(spacing: 8) {
            if repository.isLoadingMore {
                ProgressView().tint(MangaTheme.vermilion)
                Text("Loading 20 more…")
            } else if !repository.hasMoreCatalog {
                Text("You've reached the end")
            } else {
                Color.clear.frame(height: 1)
            }
        }
        .font(.system(size: 12, weight: .medium))
        .foregroundStyle(MangaTheme.secondary)
        .frame(maxWidth: .infinity, minHeight: 44)
        .id("lib-footer-\(repository.catalogBooks.count)")
        .onAppear {
            guard repository.hasMoreCatalog, !repository.isLoadingMore, !repository.isLoadingRemote else { return }
            Task { await repository.loadMore() }
        }
    }

    private func komorebiListRow(book: Audiobook) -> some View {
        HStack(spacing: 12) {
            CoverArtView(
                title: book.title,
                author: book.author,
                gradientHexes: book.coverGradientColors,
                coverImageURL: book.coverImageURL,
                cornerRadius: 8,
                ratio: 2/3
            )
            .frame(width: 54, height: 81)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    MangaBadge(book.gutenbergId != nil ? "NOVEL" : "AUDIO")
                    if book.progress > 0 {
                        Text("\(Int(book.progress * 100))%")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(MangaTheme.vermilion)
                    }
                }

                Text(book.title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(MangaTheme.ink)
                    .lineLimit(1)

                Text(book.author)
                    .font(.system(size: 11))
                    .foregroundStyle(MangaTheme.secondary)
                    .lineLimit(1)

                if book.progress > 0 {
                    ZStack(alignment: .leading) {
                        Capsule().fill(MangaTheme.surfaceHighest).frame(height: 3)
                        Capsule().fill(MangaTheme.vermilion).frame(width: 120 * CGFloat(book.progress), height: 3)
                    }
                    .padding(.top, 2)
                }
            }

            Spacer()

            Button {
                playerService.playAudiobook(book, chapterIndex: book.currentChapterIndex)
            } label: {
                Image(systemName: "play.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(MangaTheme.vermilion)
                    .clipShape(Circle())
            }
        }
        .padding(10)
        .background(MangaTheme.surfaceLow)
        .clipShape(RoundedRectangle(cornerRadius: MangaTheme.cardRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: MangaTheme.cardRadius).stroke(MangaTheme.hairline, lineWidth: 1))
    }

    private var emptyLibraryPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: selectedShelf == .downloaded ? "arrow.down.circle" : "books.vertical")
                .font(.system(size: 40))
                .foregroundStyle(MangaTheme.secondary.opacity(0.5))
                .padding(.top, 40)

            Text(selectedShelf == .downloaded ? "No Offline Audiobooks Yet" : "No Titles in this Shelf")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(MangaTheme.ink)

            Text("Browse the catalog to discover classics, audio dramas, and light novels.")
                .font(.system(size: 13))
                .foregroundStyle(MangaTheme.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)

            Button {
                nav.switchTo(.audiobooks)
            } label: {
                Text("Explore Catalog")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(MangaTheme.vermilion)
                    .clipShape(Capsule())
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - 8. Saved Bookmarks Section
    private var savedBookmarksSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            KomorebiSectionHeader(
                title: "Bookmarks & Annotations",
                japaneseSub: "栞 / SHIORI"
            )

            ForEach(playerService.bookmarks.prefix(5)) { bm in
                HStack(spacing: 12) {
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(MangaTheme.vermilion)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(bm.chapterTitle)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(MangaTheme.ink)

                        if !bm.note.isEmpty {
                            Text(bm.note)
                                .font(.system(size: 11))
                                .foregroundStyle(MangaTheme.secondary)
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    Text(bm.formattedTimestamp)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(MangaTheme.secondary)
                }
                .padding(12)
                .background(MangaTheme.surfaceLow)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(MangaTheme.hairline, lineWidth: 1))
                .padding(.horizontal, 20)
            }
        }
    }
}
