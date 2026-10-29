import SwiftUI
import UniformTypeIdentifiers

public struct MangaShelfView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Bindable var library = MangaLibrary.shared
    @State private var query = ""
    @State private var results: [MangaSeries] = []
    @State private var isSearching = false
    @State private var searchError: String?
    @State private var showingImporter = false
    @State private var importError: String?
    @State private var appeared = false
    @FocusState private var searchFocused: Bool

    private let popularTerms = ["Action", "Romance", "Horror", "Comedy", "Fantasy", "Sports"]

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                TextField("Search MangaDex", text: $query)
                    .font(.system(size: 16))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .tint(Theme.brandGreen)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Theme.surfaceWhite)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Theme.cardBorder, lineWidth: 1))
                    .focused($searchFocused)
                    .onSubmit { Task { await search() } }
                Button("Search") { Task { await search() } }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Theme.brandGreen)
                    .clipShape(Capsule())
                Button {
                    showingImporter = true
                } label: {
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.textDark)
                        .frame(width: 40, height: 40)
                        .background(Theme.surfaceWhite)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Theme.cardBorder, lineWidth: 1))
                }
                .accessibilityLabel("Import CBZ")
            }
            .padding(.horizontal, 20)

            if searchFocused || !query.isEmpty {
                if !library.recentSearches.isEmpty {
                    chipHeader("Last search") { library.clearSearches() }
                    chipRow(library.recentSearches)
                }
                chipHeader("Popular search", actionTitle: nil, action: nil)
                chipRow(popularTerms)
            }

            if let searchError {
                Text(searchError)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textMuted)
                    .padding(.horizontal, 20)
            }
            if isSearching {
                ProgressView()
                    .padding(.horizontal, 20)
            }

            if !continueSeries.isEmpty && query.isEmpty && !searchFocused {
                sectionTitle("Continue reading")
                seriesRail(continueSeries)
            }

            if let hero = results.first {
                NavigationLink {
                    MangaDetailView(series: hero, localChapters: nil)
                } label: {
                    ZStack(alignment: .bottomLeading) {
                        cover(hero)
                            .frame(height: 280)
                            .frame(maxWidth: .infinity)
                        LinearGradient(colors: [.clear, .black.opacity(0.82)], startPoint: .center, endPoint: .bottom)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(hero.title)
                                .font(.system(size: 26, weight: .bold))
                                .foregroundStyle(.white)
                                .lineLimit(2)
                            Text(hero.author)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.white.opacity(0.85))
                        }
                        .padding(16)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .padding(.horizontal, 20)
                }
                .buttonStyle(.plain)
            }

            if results.count > 1 {
                sectionTitle(query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Popular" : "Results")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(results.dropFirst().enumerated()), id: \.element.id) { index, series in
                            NavigationLink {
                                MangaDetailView(series: series, localChapters: nil)
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    cover(series)
                                        .frame(width: 112, height: 160)
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    Text(series.title)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(Theme.textDark)
                                        .lineLimit(2)
                                        .frame(width: 112, alignment: .leading)
                                }
                                .offset(y: appeared ? 0 : 16)
                                .opacity(appeared ? 1 : 0)
                                .animation(.spring(response: 0.45, dampingFraction: 0.82).delay(Double(index) * 0.04), value: appeared)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }

            if !library.imported.isEmpty {
                sectionTitle("On this device")
                seriesGrid(library.imported.map(\.series)) { series in
                    let stored = library.imported.first { $0.id == series.id }
                    return MangaDetailView(series: series, localChapters: stored?.chapters)
                }
            }

            if results.isEmpty && library.imported.isEmpty && !isSearching {
                Text("Popular titles load here. Search when you want a specific series.")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.textMuted)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
            }
        }
        .fileImporter(isPresented: $showingImporter, allowedContentTypes: [cbzType, .zip], allowsMultipleSelection: false) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                do {
                    library.add(try CBZImporter.importFile(at: url))
                } catch {
                    importError = error.localizedDescription
                }
            case .failure(let error):
                importError = error.localizedDescription
            }
        }
        .alert("Could not import", isPresented: Binding(get: { importError != nil }, set: { if !$0 { importError = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importError ?? "")
        }
        .task {
            if results.isEmpty {
                await loadPopular()
            }
            appeared = true
        }
    }

    private var cbzType: UTType {
        UTType(filenameExtension: "cbz") ?? .zip
    }

    private var continueSeries: [MangaSeries] {
        library.progress.keys.compactMap { library.series(for: $0) }
    }

    private func chipHeader(_ title: String, actionTitle: String? = "Clear", action: (() -> Void)? = nil) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Theme.textDark)
            Spacer()
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.brandGreenDark)
            }
        }
        .padding(.horizontal, 20)
    }

    private func chipRow(_ terms: [String]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(terms, id: \.self) { term in
                    Button {
                        query = term
                        searchFocused = false
                        Task { await search() }
                    } label: {
                        Text(term)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Theme.textDark)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Theme.surfaceWhite)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Theme.cardBorder, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func seriesRail(_ items: [MangaSeries]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(items) { series in
                    NavigationLink {
                        MangaDetailView(series: series, localChapters: library.imported.first { $0.id == series.id }?.chapters)
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            cover(series)
                                .frame(width: 112, height: 160)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            Text(series.title)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Theme.textDark)
                                .lineLimit(2)
                                .frame(width: 112, alignment: .leading)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 18, weight: .bold))
            .foregroundStyle(Theme.textDark)
            .padding(.horizontal, 20)
    }

    private func seriesGrid(_ items: [MangaSeries], destination: @escaping (MangaSeries) -> MangaDetailView) -> some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 16) {
            ForEach(items) { series in
                NavigationLink(destination: destination(series)) {
                    VStack(alignment: .leading, spacing: 8) {
                        cover(series)
                            .frame(height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        Text(series.title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.textDark)
                            .lineLimit(2)
                        Text(series.author)
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textMuted)
                            .lineLimit(1)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private func cover(_ series: MangaSeries) -> some View {
        if let raw = series.coverURL {
            let url = raw.hasPrefix("http") ? URL(string: raw) : URL(fileURLWithPath: raw)
            AsyncImage(url: url) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Theme.surfaceSubtle
            }
        } else {
            Theme.surfaceSubtle
        }
    }

    private func loadPopular() async {
        isSearching = true
        searchError = nil
        defer { isSearching = false }
        do {
            results = try await MangaDexService.shared.popular()
        } catch {
            searchError = error.localizedDescription
        }
    }

    private func search() async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            await loadPopular()
            return
        }
        library.noteSearch(trimmed)
        isSearching = true
        searchError = nil
        defer { isSearching = false }
        do {
            results = try await MangaDexService.shared.search(title: trimmed)
            if results.isEmpty { searchError = "No series matched that title." }
        } catch {
            searchError = error.localizedDescription
        }
    }
}
