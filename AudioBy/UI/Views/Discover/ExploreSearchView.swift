import SwiftUI

public struct ExploreSearchView: View {
    @Bindable var repository = AudiobookRepository.shared
    @Bindable var playerService = AudioPlayerService.shared
    @State private var showingFilterSheet = false
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
                    // Top Header Row
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
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    // Search Bar & Filter Button
                    HStack(spacing: 10) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(Theme.textMuted)
                            TextField("Search titles, authors, narrators...", text: $repository.searchQuery)
                                .font(.system(size: 15))
                                .foregroundColor(Theme.textDark)
                                .autocorrectionDisabled()
                                .onSubmit {
                                    Task {
                                        await repository.fetchRemoteAudiobooks()
                                    }
                                }

                            if !repository.searchQuery.isEmpty {
                                Button {
                                    repository.searchQuery = ""
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

                        // Filter Button
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

                    // Category Chips Horizontal Scroll
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(AudiobookCategory.allCases, id: \.self) { category in
                                let isSelected = repository.selectedCategory == category
                                Button {
                                    repository.selectedCategory = category
                                    Task {
                                        await repository.fetchRemoteAudiobooks(for: category)
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

                    // Results Header
                    HStack {
                        Text(repository.searchQuery.isEmpty ? "All Audiobooks" : "Search Results (\(repository.filteredAudiobooks.count))")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(Theme.textDark)

                        Spacer()

                        if repository.isLoadingRemote {
                            ProgressView()
                                .tint(Theme.brandGreen)
                                .scaleEffect(0.8)
                        } else {
                            Button {
                                Task { await repository.fetchRemoteAudiobooks() }
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
                                Task { await repository.fetchRemoteAudiobooks() }
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

                    if !repository.isLoadingRemote && repository.filteredAudiobooks.isEmpty {
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

                    // 2-Column Catalog Grid
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(repository.filteredAudiobooks) { book in
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

                    // Extra bottom padding to clear the floating mini player and dock completely
                    Spacer(minLength: 160)
                }
            }
        }
        .navigationBarHidden(true)
        .refreshable {
            await repository.fetchRemoteAudiobooks()
        }
        .sheet(isPresented: $showingFilterSheet) {
            FilterOptionsSheet()
        }
        .task(id: repository.searchQuery) {
            try? await Task.sleep(nanoseconds: 500_000_000)
            await repository.fetchRemoteAudiobooks()
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
                    // Duration Filter
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

                    // Offline Downloaded Only
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
