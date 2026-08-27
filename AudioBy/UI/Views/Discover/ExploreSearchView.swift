import SwiftUI

public struct ExploreSearchView: View {
    @Bindable var repository = AudiobookRepository.shared
    @State private var showingFilterSheet = false
    @State private var showingImporter = false
    @State private var showingPaywall = false
    @State private var localSearch = ""
    @Environment(\.dismiss) private var dismiss

    public init() {}

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    public var body: some View {
        ZStack {
            Theme.appBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 12) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Theme.textDark)
                                .frame(width: 44, height: 44)
                                .background(Theme.surfaceWhite)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Theme.cardBorder, lineWidth: 1))
                        }

                        Text("Explore")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Theme.textDark)

                        Spacer()

                        Button {
                            showingImporter = true
                        } label: {
                            Image(systemName: "doc.badge.plus")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Theme.brandGreen)
                                .frame(width: 44, height: 44)
                                .background(Theme.surfaceWhite)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Theme.cardBorder, lineWidth: 1))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    HStack(spacing: 10) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(Theme.textMuted)
                            TextField("Search titles, authors, narrators...", text: $localSearch)
                                .font(.system(size: 15))
                                .foregroundColor(Theme.textDark)
                                .autocorrectionDisabled()
                                .onSubmit {
                                    repository.searchQuery = localSearch
                                    Task { await repository.fetchRemoteAudiobooks(reset: true) }
                                }

                            if !localSearch.isEmpty {
                                Button {
                                    localSearch = ""
                                    repository.searchQuery = ""
                                    Task { await repository.fetchRemoteAudiobooks(reset: true) }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(Theme.textMuted)
                                }
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(Theme.surfaceWhite)
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Theme.cardBorder, lineWidth: 1)
                        )

                        Button {
                            showingFilterSheet = true
                        } label: {
                            Image(systemName: (repository.selectedDurationFilter != .all || repository.isOnlyDownloadedFilterActive) ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                                .font(.system(size: 20))
                                .foregroundColor((repository.selectedDurationFilter != .all || repository.isOnlyDownloadedFilterActive) ? Theme.brandGreen : Theme.textDark)
                                .frame(width: 46, height: 46)
                                .background(Theme.surfaceWhite)
                                .cornerRadius(14)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Theme.cardBorder, lineWidth: 1)
                                )
                        }
                    }
                    .padding(.horizontal, 20)

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
                                            .font(.system(size: 12))
                                        Text(category.rawValue)
                                            .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                                    }
                                    .foregroundColor(isSelected ? .black : Theme.textDark)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 9)
                                    .background(
                                        isSelected
                                            ? AnyShapeStyle(Theme.brandGreen)
                                            : AnyShapeStyle(Theme.surfaceWhite)
                                    )
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule().stroke(isSelected ? Color.clear : Theme.cardBorder, lineWidth: 1)
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    HStack {
                        Text(repository.searchQuery.isEmpty ? "All Audiobooks" : "Search Results (\(repository.exploreBooks.count))")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(Theme.textDark)

                        Spacer()

                        if repository.isLoadingRemote {
                            ProgressView()
                                .tint(Theme.brandGreen)
                                .scaleEffect(0.8)
                        } else {
                            Button {
                                Task { await repository.fetchRemoteAudiobooks(reset: true) }
                            } label: {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Theme.brandGreen)
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    if let error = repository.catalogError {
                        VStack(spacing: 8) {
                            Text(error)
                                .font(.system(size: 13))
                                .foregroundColor(Theme.textMuted)
                                .multilineTextAlignment(.center)
                            Button {
                                Task { await repository.fetchRemoteAudiobooks(reset: true) }
                            } label: {
                                Text("Retry catalog")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(Theme.brandGreen)
                                    .clipShape(Capsule())
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 20)
                    }

                    if !repository.isLoadingRemote && repository.exploreBooks.isEmpty {
                        VStack(spacing: 10) {
                            Text("No titles matched this search.")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Theme.textDark)
                            Text("Try another author or title, then retry.")
                                .font(.system(size: 13))
                                .foregroundColor(Theme.textMuted)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                    }

                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(repository.exploreBooks) { book in
                            NavigationLink(destination: AudiobookDetailView(book: book)) {
                                VStack(alignment: .leading, spacing: 8) {
                                    CoverArtView(
                                        title: book.title,
                                        author: book.author,
                                        gradientHexes: book.coverGradientColors,
                                        coverImageURL: book.coverImageURL,
                                        cornerRadius: 16,
                                        shadowRadius: 8
                                    )

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(book.title)
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(Theme.textDark)
                                            .lineLimit(1)

                                        Text(book.author)
                                            .font(.system(size: 12))
                                            .foregroundColor(Theme.textMuted)
                                            .lineLimit(1)

                                        HStack(spacing: 4) {
                                            Image(systemName: "clock")
                                                .font(.system(size: 10))
                                                .foregroundColor(Theme.textMuted)
                                            Text(book.formattedTotalDuration)
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(Theme.textDark)
                                            Spacer()
                                        }
                                        .padding(.top, 2)
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

                    if repository.hasMoreCatalog && !repository.exploreBooks.isEmpty {
                        Button {
                            Task { await repository.loadMore() }
                        } label: {
                            HStack(spacing: 8) {
                                if repository.isLoadingMore {
                                    ProgressView().tint(.black)
                                }
                                Text(repository.isLoadingMore ? "Loading more..." : "Load more")
                                    .font(.system(size: 15, weight: .bold))
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Theme.brandGreen)
                            .cornerRadius(14)
                        }
                        .disabled(repository.isLoadingMore || repository.isLoadingRemote)
                        .padding(.horizontal, 20)
                    }

                    Spacer(minLength: 160)
                }
            }
        }
        .navigationBarHidden(true)
        .refreshable {
            await repository.fetchRemoteAudiobooks(reset: true)
        }
        .sheet(isPresented: $showingFilterSheet) {
            FilterOptionsSheet()
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
        .modifier(PDFImportPresenter(isPresented: $showingImporter, showingPaywall: $showingPaywall))
        .task(id: localSearch) {
            let trimmed = localSearch.trimmingCharacters(in: .whitespacesAndNewlines)
            try? await Task.sleep(nanoseconds: 400_000_000)
            guard !Task.isCancelled else { return }
            if repository.searchQuery == trimmed { return }
            repository.searchQuery = trimmed
            await repository.fetchRemoteAudiobooks(reset: true)
        }
    }
}

private struct FilterOptionsSheet: View {
    @Bindable var repository = AudiobookRepository.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.appBackground.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Duration Length")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Theme.textDark)

                        ForEach(DurationFilter.allCases) { filter in
                            Button {
                                repository.selectedDurationFilter = filter
                            } label: {
                                HStack {
                                    Text(filter.rawValue)
                                        .foregroundColor(Theme.textDark)
                                        .font(.system(size: 15))
                                    Spacer()
                                    if repository.selectedDurationFilter == filter {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(Theme.brandGreen)
                                            .font(.system(size: 14, weight: .bold))
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                            Divider().background(Theme.cardBorder)
                        }
                    }

                    Toggle(isOn: $repository.isOnlyDownloadedFilterActive) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Downloaded Audiobooks Only")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Theme.textDark)
                            Text("Only show books saved on device for offline playback")
                                .font(.system(size: 12))
                                .foregroundColor(Theme.textMuted)
                        }
                    }
                    .tint(Theme.brandGreen)

                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Text("Apply Filters")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Theme.brandGreen)
                            .cornerRadius(16)
                    }
                }
                .padding(24)
            }
            .navigationTitle("Filter Audiobooks")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
    }
}
