import SwiftUI

public struct HomeDashboardView: View {
    @Bindable var repository = AudiobookRepository.shared

    public init() {}

    private var shelf: [Audiobook] { repository.filteredAudiobooks }

    public var body: some View {
        NavigationStack {
            ZStack {
                Theme.appBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        HStack {
                            Text("Discover")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(Theme.textDark)
                            Spacer()
                            NavigationLink(destination: ExploreSearchView()) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(Theme.textDark)
                                    .frame(width: 44, height: 44)
                                    .background(Theme.surfaceWhite)
                                    .clipShape(Circle())
                                    .shadow(color: Theme.ink.opacity(0.06), radius: 8, y: 3)
                            }
                            .accessibilityLabel("Search")
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                        Text("Discover something new")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(Theme.textDark)
                            .padding(.horizontal, 20)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(AudiobookCategory.allCases, id: \.self) { cat in
                                    let isSel = repository.selectedCategory == cat
                                    Button {
                                        repository.selectedCategory = cat
                                        Task { await repository.fetchRemoteAudiobooks(for: cat) }
                                    } label: {
                                        Text(cat == .all ? "All" : cat.rawValue)
                                            .font(.system(size: 13, weight: isSel ? .bold : .medium))
                                            .foregroundStyle(isSel ? Theme.onAccent : Theme.textDark)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(isSel ? Theme.ember : Theme.surfaceWhite)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }

                        if repository.isLoadingRemote && shelf.isEmpty {
                            HStack(spacing: 10) {
                                ProgressView().tint(Theme.ember)
                                Text("Loading the catalog…")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Theme.textMuted)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                        }

                        if let error = repository.catalogError, shelf.isEmpty {
                            VStack(spacing: 10) {
                                Text(repository.isShowingCachedCatalog ? "Couldn't refresh. Showing the saved catalog." : error)
                                    .font(.system(size: 13))
                                    .foregroundStyle(Theme.textMuted)
                                    .multilineTextAlignment(.center)
                                Button {
                                    Task { await repository.fetchRemoteAudiobooks() }
                                } label: {
                                    Text("Retry")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(Theme.onAccent)
                                        .padding(.horizontal, 18)
                                        .padding(.vertical, 10)
                                        .background(Theme.ember)
                                        .clipShape(Capsule())
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 20)
                        }

                        if !repository.continueListeningBooks.isEmpty {
                            posterShelf(title: "Continue", books: repository.continueListeningBooks)
                        }

                        if !shelf.isEmpty {
                            posterShelf(title: "New releases", books: Array(shelf.prefix(12)))
                            posterShelf(
                                title: "Most played",
                                books: Array(shelf.sorted { $0.listenCount > $1.listenCount }.prefix(12))
                            )
                            let more = Array(shelf.dropFirst(12).prefix(12))
                            if !more.isEmpty {
                                posterShelf(title: "More to hear", books: more)
                            }
                        } else if !repository.isLoadingRemote && repository.catalogError == nil {
                            Text("No audiobooks yet")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Theme.textDark)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 28)
                        }

                        Spacer(minLength: 150)
                    }
                }
            }
            .navigationBarHidden(true)
            .refreshable {
                await repository.fetchRemoteAudiobooks()
            }
        }
    }

    private func posterShelf(title: String, books: [Audiobook]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Theme.textDark)
                Spacer()
                NavigationLink(destination: ExploreSearchView()) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.textMuted)
                        .frame(width: 32, height: 32)
                }
                .accessibilityLabel("See all \(title)")
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 14) {
                    ForEach(books) { book in
                        NavigationLink(destination: AudiobookDetailView(book: book)) {
                            CatalogPoster(book: book)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}
