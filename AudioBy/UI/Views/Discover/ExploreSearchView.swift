import SwiftUI

/// Japanese editorial Search & Catalog Explore screen.
/// Directly implements the Komorebi Discover design matching stitch_reference/discover_hub.
public struct ExploreSearchView: View {
    @Bindable var repository = AudiobookRepository.shared
    @State private var showingFilterSheet = false
    @State private var showingImporter = false
    @State private var showingPaywall = false
    @State private var localSearch = ""
    @State private var section: ExploreSection = .books
    @Environment(\.dismiss) private var dismiss

    public init() {}

    public var body: some View {
        ZStack {
            MangaTheme.surface.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    // Top Bar
                    HStack(spacing: 12) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(MangaTheme.ink)
                                .frame(width: 44, height: 44)
                                .background(MangaTheme.surfaceLow)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(MangaTheme.hairline, lineWidth: 1))
                        }

                        VStack(alignment: .leading, spacing: 1) {
                            Text("EXPLORE CATALOG")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(1.2)
                                .foregroundStyle(MangaTheme.vermilion)
                            Text("Discover")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(MangaTheme.ink)
                        }

                        Spacer()

                        Button {
                            showingImporter = true
                        } label: {
                            Image(systemName: "doc.badge.plus")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(MangaTheme.vermilion)
                                .frame(width: 44, height: 44)
                                .background(MangaTheme.surfaceLow)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(MangaTheme.hairline, lineWidth: 1))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    // Explore Section Selector (Books, Manga)
                    HStack(spacing: 8) {
                        ForEach(ExploreSection.allCases) { item in
                            let isSel = section == item
                            Button {
                                section = item
                            } label: {
                                Text(item.title)
                                    .font(.system(size: 13, weight: isSel ? .bold : .medium))
                                    .foregroundStyle(isSel ? .white : MangaTheme.ink)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(isSel ? MangaTheme.vermilion : MangaTheme.surfaceLow)
                                    .clipShape(Capsule())
                                    .overlay(Capsule().stroke(isSel ? Color.clear : MangaTheme.hairline, lineWidth: 1))
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    if section == .manga {
                        MangaShelfView()
                    } else {
                        // Search Bar & Filter Button
                        HStack(spacing: 10) {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundStyle(MangaTheme.secondary)

                                TextField("Search titles, authors, narrators…", text: $localSearch)
                                    .font(.system(size: 14))
                                    .foregroundStyle(MangaTheme.ink)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                                    .submitLabel(.search)
                                    .onSubmit { runBookSearch() }
                                    .onChange(of: localSearch) { _, newValue in
                                        repository.searchQuery = newValue
                                    }

                                if !localSearch.isEmpty {
                                    Button {
                                        localSearch = ""
                                        repository.searchQuery = ""
                                        Task { await repository.fetchRemoteAudiobooks(reset: true) }
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(MangaTheme.secondary)
                                    }
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(MangaTheme.surfaceLow)
                            .clipShape(RoundedRectangle(cornerRadius: MangaTheme.cardRadius, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: MangaTheme.cardRadius).stroke(MangaTheme.hairline, lineWidth: 1))

                            Button {
                                showingFilterSheet = true
                            } label: {
                                Image(systemName: (repository.selectedDurationFilter != .all || repository.isOnlyDownloadedFilterActive) ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                                    .font(.system(size: 20))
                                    .foregroundStyle((repository.selectedDurationFilter != .all || repository.isOnlyDownloadedFilterActive) ? MangaTheme.vermilion : MangaTheme.ink)
                                    .frame(width: 46, height: 46)
                                    .background(MangaTheme.surfaceLow)
                                    .clipShape(RoundedRectangle(cornerRadius: MangaTheme.cardRadius, style: .continuous))
                                    .overlay(RoundedRectangle(cornerRadius: MangaTheme.cardRadius).stroke(MangaTheme.hairline, lineWidth: 1))
                            }
                        }
                        .padding(.horizontal, 20)

                        // Category Pill Rail
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(AudiobookCategory.allCases, id: \.self) { category in
                                    let isSelected = repository.selectedCategory == category
                                    Button {
                                        repository.selectedCategory = category
                                        Task {
                                            await repository.fetchRemoteAudiobooks(for: category, reset: true)
                                        }
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: category.iconName)
                                                .font(.system(size: 11))
                                            Text(category.rawValue)
                                                .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                                        }
                                        .foregroundStyle(isSelected ? .white : MangaTheme.ink)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(isSelected ? MangaTheme.vermilion : MangaTheme.surfaceLow)
                                        .clipShape(Capsule())
                                        .overlay(Capsule().stroke(isSelected ? Color.clear : MangaTheme.hairline, lineWidth: 1))
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }

                        // Search Results Header
                        HStack {
                            Text(repository.searchQuery.isEmpty ? "All Audiobooks & Novels" : "Results (\(repository.exploreBooks.count))")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(MangaTheme.ink)

                            Spacer()

                            if repository.isLoadingRemote {
                                ProgressView()
                                    .tint(MangaTheme.vermilion)
                                    .scaleEffect(0.8)
                            } else {
                                Button {
                                    Task { await repository.fetchRemoteAudiobooks(reset: true) }
                                } label: {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(MangaTheme.vermilion)
                                }
                            }
                        }
                        .padding(.horizontal, 20)

                        if let error = repository.catalogError {
                            VStack(spacing: 8) {
                                Text(error)
                                    .font(.system(size: 13))
                                    .foregroundStyle(MangaTheme.secondary)
                                    .multilineTextAlignment(.center)
                                Button {
                                    Task { await repository.fetchRemoteAudiobooks(reset: true) }
                                } label: {
                                    Text("Retry catalog")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(MangaTheme.vermilion)
                                        .clipShape(Capsule())
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 20)
                        }

                        // 2-Column Grid of Books
                        if repository.exploreBooks.isEmpty && !repository.isLoadingRemote {
                            VStack(spacing: 10) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 34))
                                    .foregroundStyle(MangaTheme.secondary.opacity(0.5))
                                    .padding(.top, 20)
                                Text("No audiobooks found")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(MangaTheme.ink)
                                Text("Try adjusting your search terms or filters.")
                                    .font(.system(size: 13))
                                    .foregroundStyle(MangaTheme.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 30)
                        } else {
                            LazyVGrid(
                                columns: DuoLayout.adaptiveCardColumns,
                                spacing: 18
                            ) {
                                ForEach(repository.exploreBooks) { book in
                                    NavigationLink(destination: AudiobookDetailView(book: book)) {
                                        KomorebiBookCard(book: book)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 20)
                        }

                        if repository.hasMoreCatalog && !repository.exploreBooks.isEmpty {
                            Button {
                                Task { await repository.loadMore() }
                            } label: {
                                HStack(spacing: 8) {
                                    if repository.isLoadingMore {
                                        ProgressView().tint(MangaTheme.vermilion)
                                    }
                                    Text(repository.isLoadingMore ? "Loading more titles…" : "Load More Titles")
                                        .font(.system(size: 13, weight: .bold))
                                }
                                .foregroundStyle(MangaTheme.vermilion)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(MangaTheme.surfaceLow)
                                .clipShape(RoundedRectangle(cornerRadius: MangaTheme.cardRadius))
                                .overlay(RoundedRectangle(cornerRadius: MangaTheme.cardRadius).stroke(MangaTheme.hairline, lineWidth: 1))
                                .padding(.horizontal, 20)
                            }
                        }
                    }

                    Spacer(minLength: 160)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingFilterSheet) {
            FilterOptionsSheet()
        }
        .modifier(PDFImportPresenter(isPresented: $showingImporter, showingPaywall: $showingPaywall))
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
    }

    private func runBookSearch() {
        let trimmed = localSearch.trimmingCharacters(in: .whitespacesAndNewlines)
        repository.searchQuery = trimmed
        Task {
            await repository.fetchRemoteAudiobooks(reset: true)
        }
    }
}

private enum ExploreSection: String, CaseIterable, Identifiable {
    case books
    case manga

    var id: String { rawValue }
    var title: String {
        switch self {
        case .books: return "Audiobooks & Novels"
        case .manga: return "Manga Lounge"
        }
    }
}

private struct FilterOptionsSheet: View {
    @Bindable var repository = AudiobookRepository.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                MangaTheme.surface.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        // Duration Filters
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Duration Length")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(MangaTheme.ink)

                            ForEach(DurationFilter.allCases) { filter in
                                Button {
                                    repository.selectedDurationFilter = filter
                                } label: {
                                    HStack {
                                        Text(filter.rawValue)
                                            .foregroundStyle(MangaTheme.ink)
                                            .font(.system(size: 14))
                                        Spacer()
                                        if repository.selectedDurationFilter == filter {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(MangaTheme.vermilion)
                                                .font(.system(size: 13, weight: .bold))
                                        }
                                    }
                                    .padding(.vertical, 8)
                                }
                                Divider().background(MangaTheme.hairline)
                            }
                        }

                        // Offline toggle
                        Toggle(isOn: $repository.isOnlyDownloadedFilterActive) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Downloaded Titles Only")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(MangaTheme.ink)
                                Text("Only show books saved on device for offline playback")
                                    .font(.system(size: 12))
                                    .foregroundStyle(MangaTheme.secondary)
                            }
                        }
                        .tint(MangaTheme.vermilion)

                        // Action Buttons
                        HStack(spacing: 12) {
                            Button {
                                repository.selectedDurationFilter = .all
                                repository.isOnlyDownloadedFilterActive = false
                                repository.selectedCategory = .all
                            } label: {
                                Text("Reset All")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(MangaTheme.ink)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                    .background(MangaTheme.surfaceHigh)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(MangaTheme.hairline, lineWidth: 1))
                            }

                            Button {
                                dismiss()
                            } label: {
                                Text("Apply Filters")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                    .background(MangaTheme.vermilion)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }
                        .padding(.top, 10)
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Filter Catalog")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(MangaTheme.vermilion)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
