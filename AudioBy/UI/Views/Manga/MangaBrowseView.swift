import SwiftUI

public struct MangaBrowseView: View {
    @Bindable var library = MangaLibrary.shared
    @State private var query = ""
    @State private var selectedSource: MangaSource = .all
    @State private var results: [MangaSeries] = MangaDexService.curatedCatalog + MangaDexService.webtoonCatalog + MangaDexService.vintageArchiveCatalog
    @State private var isSearching = false
    @State private var searchError: String?
    @FocusState private var isFieldFocused: Bool

    private let popularGenres = ["Action", "Fantasy", "Mystery", "Slice of Life", "Dark Fantasy", "Romance", "Supernatural", "Comedy", "Sports", "Historical", "Sci-Fi"]

    public init() {}

    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                // Search Input Box
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(MangaTheme.secondary)
                    TextField("Search titles, creators, scanlators...", text: $query)
                        .font(.system(size: 15))
                        .foregroundStyle(MangaTheme.ink)
                        .focused($isFieldFocused)
                        .submitLabel(.search)
                        .onSubmit { Task { await executeSearch() } }
                        .onChange(of: query) { _, _ in
                            Task { await executeSearch() }
                        }
                    if !query.isEmpty {
                        Button {
                            query = ""
                            Task { await executeSearch() }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 15))
                                .foregroundStyle(MangaTheme.secondary)
                        }
                    }
                    Button("Search") {
                        Task { await executeSearch() }
                    }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(MangaTheme.vermilion, in: Capsule())
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(MangaTheme.surfaceLow)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(MangaTheme.hairline, lineWidth: 1))
                .padding(.horizontal, 16)

                // Source Pills Row
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(MangaSource.allCases) { src in
                            let isSel = selectedSource == src
                            Button {
                                selectedSource = src
                                Task { await executeSearch() }
                            } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: src.icon)
                                        .font(.system(size: 11))
                                    Text(src.rawValue)
                                        .font(.system(size: 12, weight: isSel ? .bold : .medium))
                                }
                                .foregroundStyle(isSel ? .white : MangaTheme.ink)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(isSel ? MangaTheme.vermilion : MangaTheme.surfaceLow)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(isSel ? Color.clear : MangaTheme.hairline, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                }

                // Recent Searches
                if !library.recentSearches.isEmpty && query.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Recent Searches")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(MangaTheme.ink)
                            Spacer()
                            Button("Clear") {
                                library.clearSearches()
                            }
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(MangaTheme.vermilion)
                        }
                        .padding(.horizontal, 16)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(library.recentSearches, id: \.self) { term in
                                    Button {
                                        query = term
                                        Task { await executeSearch() }
                                    } label: {
                                        Text(term)
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundStyle(MangaTheme.ink)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(MangaTheme.surfaceContainer)
                                            .clipShape(Capsule())
                                            .overlay(Capsule().stroke(MangaTheme.hairline, lineWidth: 1))
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                }

                // Genre Cloud
                VStack(alignment: .leading, spacing: 8) {
                    Text("Explore by Tropes & Genres")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(MangaTheme.ink)
                        .padding(.horizontal, 16)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(popularGenres, id: \.self) { genre in
                                Button {
                                    query = genre
                                    Task { await executeSearch() }
                                } label: {
                                    Text(genre)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(MangaTheme.ink)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 7)
                                        .background(MangaTheme.surfaceLow)
                                        .clipShape(Capsule())
                                        .overlay(Capsule().stroke(MangaTheme.hairline, lineWidth: 1))
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }

                if isSearching {
                    HStack(spacing: 10) {
                        ProgressView().tint(MangaTheme.vermilion)
                        Text("Searching MangaDex...")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(MangaTheme.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }

                // Results Grid
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(query.isEmpty ? "Curated Serializations" : "Search Results (\(results.count))")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(MangaTheme.ink)
                        Spacer()
                    }
                    .padding(.horizontal, 16)

                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 14),
                            GridItem(.flexible(), spacing: 14)
                        ],
                        spacing: 16
                    ) {
                        ForEach(results) { series in
                            NavigationLink(destination: MangaDetailView(series: series, localChapters: nil)) {
                                VStack(alignment: .leading, spacing: 6) {
                                    MangaCoverCard(series: series, badgeText: series.status ?? "ONGOING")
                                        .frame(maxWidth: .infinity)

                                    Text(series.title)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(MangaTheme.ink)
                                        .lineLimit(1)

                                    Text(series.author)
                                        .font(.system(size: 12))
                                        .foregroundStyle(MangaTheme.secondary)
                                        .lineLimit(1)

                                    HStack {
                                        Text("Ch. \(series.totalChapters ?? 128)")
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundStyle(MangaTheme.secondary)
                                        Spacer()
                                        HStack(spacing: 2) {
                                            Image(systemName: "star.fill")
                                                .font(.system(size: 9))
                                                .foregroundStyle(MangaTheme.vermilion)
                                            Text(String(format: "%.2f", series.rating ?? 4.9))
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundStyle(MangaTheme.ink)
                                        }
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                }

                Spacer(minLength: 60)
            }
            .padding(.vertical, 8)
        }
        .background(MangaTheme.surface)
    }

    private func executeSearch() async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            library.noteSearch(trimmed)
        }
        isSearching = true
        defer { isSearching = false }
            let fetched = await MangaCatalogService.shared.search(trimmed, source: selectedSource)
            results = fetched
    }
}

