import SwiftUI

/// Novels section: real public-domain novels from Project Gutenberg, readable in-app.
public struct NovelsRootView: View {
    @Bindable private var nav = AppNavigationState.shared
    @State private var books: [Audiobook] = []
    @State private var loading = false
    @State private var error: String?
    @State private var query = ""
    @State private var topic: String? = nil
    @State private var opened: Audiobook?

    private let topics: [(String, String?)] = [
        ("Popular", nil), ("Fantasy", "fantasy"), ("Adventure", "adventure"), ("Sci-Fi", "science fiction"),
        ("Romance", "romance"), ("Mystery", "detective"), ("Japan", "japan"), ("Horror", "horror")
    ]

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(topics, id: \.0) { t in
                                Button { topic = t.1; query = ""; Task { await load() } } label: {
                                    Text(t.0).font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(topic == t.1 ? .white : MangaTheme.ink)
                                        .padding(.horizontal, 14).padding(.vertical, 8)
                                        .background(topic == t.1 ? MangaTheme.vermilion : MangaTheme.surfaceLow, in: Capsule())
                                        .overlay(Capsule().stroke(MangaTheme.hairline, lineWidth: 1))
                                }.buttonStyle(.plain)
                            }
                        }.padding(.horizontal, 20)
                    }
                    if loading && books.isEmpty {
                        ProgressView().tint(MangaTheme.vermilion).frame(maxWidth: .infinity).padding(.top, 40)
                    } else if books.isEmpty {
                        VStack(spacing: 12) {
                            Text(error ?? "No novels found for that search.")
                                .font(.system(size: 14)).foregroundStyle(MangaTheme.secondary)
                                .multilineTextAlignment(.center)
                            Button("Retry") { Task { await load() } }
                                .font(.system(size: 14, weight: .bold)).foregroundStyle(MangaTheme.vermilion)
                        }
                        .frame(maxWidth: .infinity).padding(.top, 40).padding(.horizontal, 30)
                    } else {
                        LazyVGrid(columns: DuoLayout.adaptiveCardColumns, spacing: 18) {
                            ForEach(books) { book in
                                Button { opened = book } label: {
                                    KomorebiBookCard(book: book, badgeText: "NOVEL", showProgress: false)
                                }.buttonStyle(.plain)
                            }
                        }.padding(.horizontal, 20)
                    }
                    Spacer(minLength: 60)
                }
            }
            .background(MangaTheme.surface.ignoresSafeArea())
            .navigationBarHidden(true)
            .navigationDestination(item: $opened) { NovelDetailScreen(book: $0) }
            .refreshable { await load() }
            .task { if books.isEmpty { await load() } }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Button { nav.openSidebar() } label: {
                    Image(systemName: "line.3.horizontal").font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(MangaTheme.ink).frame(width: 44, height: 44)
                        .background(MangaTheme.surfaceLow, in: Circle())
                        .overlay(Circle().stroke(MangaTheme.hairline, lineWidth: 1))
                }
                Text("Novels").font(.system(size: 24, weight: .bold)).foregroundStyle(MangaTheme.ink)
                Spacer()
            }
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass").foregroundStyle(MangaTheme.secondary)
                TextField("Search novels and authors", text: $query)
                    .submitLabel(.search)
                    .onSubmit { Task { await load() } }
                    .foregroundStyle(MangaTheme.ink)
            }
            .padding(12)
            .background(MangaTheme.surfaceLow, in: RoundedRectangle(cornerRadius: MangaTheme.cardRadius))
            .overlay(RoundedRectangle(cornerRadius: MangaTheme.cardRadius).stroke(MangaTheme.hairline, lineWidth: 1))
        }
        .padding(.horizontal, 20).padding(.top, 8)
    }

    private func load() async {
        loading = true
        error = nil
        do { books = try await AudiobookAPIService.shared.fetchNovels(query: query, topic: topic) }
        catch { books = []; self.error = "Couldn't reach the novel library. Check your connection and tap Retry." }
        loading = false
    }
}

struct NovelDetailScreen: View {
    let book: Audiobook
    @Environment(\.dismiss) private var dismiss
    @State private var chapters: [Chapter] = []
    @State private var loading = true
    @State private var failed = false
    @State private var reading: Chapter?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "arrow.left").font(.system(size: 16, weight: .bold))
                            .foregroundStyle(MangaTheme.ink).frame(width: 44, height: 44)
                            .background(MangaTheme.surfaceLow, in: Circle())
                            .overlay(Circle().stroke(MangaTheme.hairline, lineWidth: 1))
                    }
                    Spacer()
                }
                HStack(alignment: .top, spacing: 16) {
                    CoverArtView(title: book.title, author: book.author, gradientHexes: book.coverGradientColors,
                                 coverImageURL: book.coverImageURL, cornerRadius: 10, ratio: 2/3)
                        .frame(width: 110, height: 165)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(book.title).font(.system(size: 20, weight: .bold)).foregroundStyle(MangaTheme.ink)
                        Text(book.author).font(.system(size: 14)).foregroundStyle(MangaTheme.secondary)
                        if !chapters.isEmpty {
                            Text("\(chapters.count) chapters").font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(MangaTheme.vermilion)
                        }
                    }
                }
                if let first = chapters.first {
                    Button { reading = first } label: {
                        Label("Start reading", systemImage: "book.pages.fill")
                            .font(.system(size: 15, weight: .bold)).foregroundStyle(.white)
                            .frame(maxWidth: .infinity).frame(height: 50)
                            .background(MangaTheme.vermilion, in: RoundedRectangle(cornerRadius: 14))
                    }
                }
                if loading {
                    ProgressView().tint(MangaTheme.vermilion).frame(maxWidth: .infinity).padding(.top, 20)
                } else if failed {
                    Text("Couldn't load this novel's text. Check your connection and try again.")
                        .font(.system(size: 13)).foregroundStyle(MangaTheme.secondary)
                } else {
                    ForEach(chapters) { ch in
                        Button { reading = ch } label: {
                            HStack {
                                Text(ch.title).font(.system(size: 14, weight: .semibold)).foregroundStyle(MangaTheme.ink).lineLimit(1)
                                Spacer()
                                Image(systemName: "chevron.right").font(.system(size: 12)).foregroundStyle(MangaTheme.secondary)
                            }
                            .padding(14)
                            .background(MangaTheme.surfaceLow, in: RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(MangaTheme.hairline, lineWidth: 1))
                        }.buttonStyle(.plain)
                    }
                }
            }
            .padding(20)
        }
        .background(MangaTheme.surface.ignoresSafeArea())
        .navigationBarHidden(true)
        .fullScreenCover(item: $reading) { BookReaderView(book: book, chapter: $0) }
        .task {
            do {
                chapters = try await AudiobookAPIService.shared.loadNovelChapters(for: book).filter { $0.hasReadableText }
                failed = chapters.isEmpty
            } catch { failed = true }
            loading = false
        }
    }
}
