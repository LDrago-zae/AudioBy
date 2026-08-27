import SwiftUI

public enum LibraryShelf: String, CaseIterable, Identifiable {
    case inProgress = "Listening"
    case saved = "Saved"
    case downloaded = "Downloads"
    case finished = "Finished"

    public var id: String { rawValue }
}

public struct LibraryView: View {
    @Bindable var repository = AudiobookRepository.shared
    @Bindable var playerService = AudioPlayerService.shared
    @Bindable var downloadManager = DownloadManager.shared
    @State private var selectedShelf: LibraryShelf = .inProgress
    @State private var showingClearConfirmation = false

    public init() {}

    private var currentBooks: [Audiobook] {
        switch selectedShelf {
        case .inProgress:
            return repository.continueListeningBooks
        case .saved:
            return repository.favoriteBooks
        case .downloaded:
            return repository.downloadedBooks
        case .finished:
            return repository.finishedBooks
        }
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                Theme.appBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        // Segmented Shelf Picker
                        HStack(spacing: 6) {
                            ForEach(LibraryShelf.allCases) { shelf in
                                let isSelected = selectedShelf == shelf
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        selectedShelf = shelf
                                    }
                                } label: {
                                    Text(shelf.rawValue)
                                        .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                                        .foregroundColor(isSelected ? .black : Theme.textDark)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(
                                            isSelected ? AnyShapeStyle(Theme.brandGreen) : AnyShapeStyle(Theme.surfaceWhite)
                                        )
                                        .clipShape(Capsule())
                                        .overlay(
                                            Capsule().stroke(isSelected ? Color.clear : Theme.cardBorder, lineWidth: 1)
                                        )
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                        // Downloaded Storage Banner (Visible on Downloads Shelf)
                        if selectedShelf == .downloaded {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Offline Storage Usage")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(Theme.textDark)
                                    Text("\(downloadManager.formattedStorageUsed) used across \(downloadManager.downloadedBookIds.count) audiobooks")
                                        .font(.system(size: 12))
                                        .foregroundColor(Theme.textMuted)
                                }

                                Spacer()

                                if !downloadManager.downloadedBookIds.isEmpty {
                                    Button {
                                        showingClearConfirmation = true
                                    } label: {
                                        Text("Clear Cache")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.red)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(Color.red.opacity(0.15))
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                            .padding(14)
                            .background(Theme.surfaceWhite)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Theme.cardBorder, lineWidth: 1)
                            )
                            .padding(.horizontal, 20)
                        }

                        // Book Shelf Grid
                        if currentBooks.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: selectedShelf == .downloaded ? "arrow.down.circle" : "books.vertical")
                                    .font(.system(size: 40))
                                    .foregroundColor(Theme.textMuted.opacity(0.5))
                                    .padding(.top, 40)

                                Text(selectedShelf == .downloaded ? "No Offline Downloads Yet" : "No Audiobooks in this Shelf")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(Theme.textDark)

                                Text("Explore the catalog and tap the download or bookmark icon to save titles here.")
                                    .font(.system(size: 13))
                                    .foregroundColor(Theme.textMuted)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 30)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 16) {
                                ForEach(currentBooks) { book in
                                    NavigationLink(destination: AudiobookDetailView(book: book)) {
                                        VStack(alignment: .leading, spacing: 8) {
                                            CoverArtView(
                                                title: book.title,
                                                author: book.author,
                                                gradientHexes: book.coverGradientColors,
                                                coverImageURL: book.coverImageURL,
                                                cornerRadius: 16,
                                                shadowRadius: 6
                                            )

                                            VStack(alignment: .leading, spacing: 3) {
                                                Text(book.title)
                                                    .font(.system(size: 14, weight: .bold))
                                                    .foregroundColor(Theme.textDark)
                                                    .lineLimit(1)

                                                Text(book.author)
                                                    .font(.system(size: 12))
                                                    .foregroundColor(Theme.textMuted)
                                                    .lineLimit(1)

                                                // Progress bar
                                                if book.progress > 0 {
                                                    GeometryReader { g in
                                                        ZStack(alignment: .leading) {
                                                            Capsule().fill(Theme.surfaceSubtle).frame(height: 3)
                                                            Capsule().fill(Theme.brandGreen).frame(width: CGFloat(book.progress) * g.size.width, height: 3)
                                                        }
                                                    }
                                                    .frame(height: 3)
                                                    .padding(.top, 2)
                                                }
                                            }
                                        }
                                        .padding(10)
                                        .background(Theme.surfaceWhite)
                                        .cornerRadius(18)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 18)
                                                .stroke(Theme.cardBorder, lineWidth: 1)
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }

                        // Saved Bookmarks & Notes Shortcut Section
                        if !playerService.bookmarks.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Saved Bookmarks & Notes (\(playerService.bookmarks.count))")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(Theme.textDark)
                                    .padding(.horizontal, 20)

                                ForEach(playerService.bookmarks.prefix(5)) { bookmark in
                                    HStack(spacing: 12) {
                                        Image(systemName: "bookmark.fill")
                                            .foregroundColor(Theme.brandGreen)
                                            .font(.system(size: 16))

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(bookmark.chapterTitle)
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(Theme.textDark)

                                            if !bookmark.note.isEmpty {
                                                Text(bookmark.note)
                                                    .font(.system(size: 12))
                                                    .foregroundColor(Theme.textMuted)
                                                    .lineLimit(1)
                                            }
                                        }

                                        Spacer()

                                        Text(bookmark.formattedTimestamp)
                                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                                            .foregroundColor(Theme.brandGreen)
                                    }
                                    .padding(14)
                                    .background(Theme.surfaceWhite)
                                    .cornerRadius(14)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Theme.cardBorder, lineWidth: 1)
                                    )
                                    .padding(.horizontal, 20)
                                }
                            }
                        }

                        Spacer(minLength: 160)
                    }
                }
            }
            .navigationTitle("My Library")
            .navigationBarTitleDisplayMode(.inline)
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
}
