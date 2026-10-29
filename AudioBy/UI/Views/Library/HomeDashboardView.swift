import SwiftUI

public struct HomeDashboardView: View {
    @Bindable var playerService = AudioPlayerService.shared
    @Bindable var repository = AudiobookRepository.shared

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                Theme.appBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        // Top Header Row
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Welcome back")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Theme.textMuted)
                                Text("Find your next audiobook")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(Theme.textDark)
                                    .tracking(-0.6)
                            }

                            Spacer()

                            HStack(spacing: 12) {
                                // Search shortcut
                                NavigationLink(destination: ExploreSearchView()) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(Theme.textDark)
                                        .frame(width: 44, height: 44)
                                        .background(Theme.surfaceWhite)
                                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .stroke(Theme.cardBorder, lineWidth: 1)
                                        )
                                }

                                // Profile Avatar
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 44, height: 44)
                                    .foregroundColor(Theme.stone)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white.opacity(0.2), lineWidth: 2)
                                    )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                        Image("SceneLantern")
                            .resizable()
                            .scaledToFill()
                            .frame(height: 168)
                            .frame(maxWidth: .infinity)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                            .padding(.horizontal, 20)
                            .accessibilityLabel("A reader under a lantern in a library")

                        if repository.isLoadingRemote && repository.audiobooks.isEmpty {
                            HStack(spacing: 10) {
                                ProgressView().tint(Theme.brandGreen)
                                Text("Loading the LibriVox catalog...")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Theme.textMuted)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                        }

                        if let error = repository.catalogError {
                            VStack(spacing: 10) {
                                Text(repository.isShowingCachedCatalog ? "Couldn't refresh. Showing saved catalog." : error)
                                    .font(.system(size: 13))
                                    .foregroundColor(Theme.textMuted)
                                    .multilineTextAlignment(.center)
                                Button {
                                    Task { await repository.fetchRemoteAudiobooks() }
                                } label: {
                                    Text("Retry")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 18)
                                        .padding(.vertical, 10)
                                        .background(Theme.brandGreen)
                                        .clipShape(Capsule())
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .padding(.horizontal, 20)
                        }

                        if !repository.isLoadingRemote && repository.audiobooks.isEmpty && repository.catalogError == nil {
                            VStack(spacing: 10) {
                                Text("No audiobooks yet")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(Theme.textDark)
                                Button {
                                    Task { await repository.fetchRemoteAudiobooks() }
                                } label: {
                                    Text("Load catalog")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 18)
                                        .padding(.vertical, 10)
                                        .background(Theme.brandGreen)
                                        .clipShape(Capsule())
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                        }

                        if !repository.continueListeningBooks.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Continue")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(Theme.textDark)
                                    .padding(.horizontal, 20)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(repository.continueListeningBooks) { book in
                                            NavigationLink(destination: AudiobookDetailView(book: book)) {
                                                VStack(alignment: .leading, spacing: 8) {
                                                    CoverArtView(
                                                        title: book.title,
                                                        author: book.author,
                                                        gradientHexes: book.coverGradientColors,
                                                        coverImageURL: book.coverImageURL,
                                                        cornerRadius: 8,
                                                        shadowRadius: 6
                                                    )
                                                    .frame(width: 132, height: 132)

                                                    Text(book.title)
                                                        .font(.system(size: 14, weight: .semibold))
                                                        .foregroundColor(Theme.textDark)
                                                        .lineLimit(2)
                                                        .frame(width: 132, alignment: .leading)

                                                    GeometryReader { g in
                                                        ZStack(alignment: .leading) {
                                                            Capsule().fill(Theme.surfaceSubtle).frame(height: 3)
                                                            Capsule()
                                                                .fill(Theme.textDark)
                                                                .frame(width: max(4, CGFloat(book.progress) * g.size.width), height: 3)
                                                        }
                                                    }
                                                    .frame(width: 132, height: 3)
                                                }
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }
                        }

                        if let hero = repository.featuredHeroBooks.first {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("A place to start")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(Theme.textDark)
                                    .padding(.horizontal, 20)

                                NavigationLink(destination: AudiobookDetailView(book: hero)) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                                            .fill(Theme.surfaceWhite)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                                    .stroke(Theme.cardBorder, lineWidth: 1)
                                            )

                                        HStack(alignment: .center, spacing: 14) {
                                            // Real cover thumbnail
                                            CoverArtView(
                                                title: hero.title,
                                                author: hero.author,
                                                gradientHexes: hero.coverGradientColors,
                                                coverImageURL: hero.coverImageURL,
                                                cornerRadius: 14,
                                                shadowRadius: 6
                                            )
                                            .frame(width: 105, height: 105)

                                            VStack(alignment: .leading, spacing: 6) {
                                                HStack {
                                                    Text(hero.category.rawValue.uppercased())
                                                        .font(.system(size: 9, weight: .bold))
                                                        .foregroundColor(Theme.brandGreenLight)
                                                        .padding(.horizontal, 7)
                                                        .padding(.vertical, 3)
                                                        .background(Theme.brandGreen.opacity(0.15))
                                                        .clipShape(Capsule())

                                                    Spacer()

                                                    HStack(spacing: 3) {
                                                        Image(systemName: "headphones")
                                                            .font(.system(size: 10))
                                                            .foregroundColor(Theme.brandGreen)
                                                        Text(hero.formattedListenCount)
                                                            .font(.system(size: 11, weight: .bold))
                                                            .foregroundColor(Theme.textDark)
                                                    }
                                                }

                                                Text(hero.title)
                                                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                                                    .foregroundColor(Theme.textDark)
                                                    .lineLimit(2)

                                                Text("By \(hero.author)")
                                                    .font(.system(size: 12, weight: .medium))
                                                    .foregroundColor(Theme.textMuted)
                                                    .lineLimit(1)

                                                // Action Row
                                                HStack(spacing: 8) {
                                                    Button {
                                                        playerService.playAudiobook(hero, chapterIndex: 0, autoPlay: true)
                                                    } label: {
                                                        HStack(spacing: 4) {
                                                            Image(systemName: "play.fill")
                                                                .font(.system(size: 9, weight: .bold))
                                                            Text("Play")
                                                                .font(.system(size: 11, weight: .bold))
                                                        }
                                                        .foregroundColor(.black)
                                                        .padding(.horizontal, 12)
                                                        .padding(.vertical, 6)
                                                        .background(Theme.brandGreen)
                                                        .clipShape(Capsule())
                                                    }

                                                    Button {
                                                        playerService.playSamplePreview(for: hero)
                                                    } label: {
                                                        HStack(spacing: 4) {
                                                            Image(systemName: "sparkles")
                                                                .font(.system(size: 9))
                                                            Text("30s Sample")
                                                                .font(.system(size: 11, weight: .bold))
                                                        }
                                                        .foregroundColor(Theme.textDark)
                                                        .padding(.horizontal, 9)
                                                        .padding(.vertical, 6)
                                                        .background(Theme.surfaceSubtle)
                                                        .clipShape(Capsule())
                                                    }
                                                }
                                                .padding(.top, 2)
                                            }
                                        }
                                        .padding(14)
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }
                        }

                        // Category Pills Horizontal Scroll
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Browse by Genre")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(Theme.textDark)
                                .padding(.horizontal, 20)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(AudiobookCategory.allCases, id: \.self) { cat in
                                        let isSel = repository.selectedCategory == cat
                                        Button {
                                            repository.selectedCategory = cat
                                            Task { await repository.fetchRemoteAudiobooks(for: cat) }
                                        } label: {
                                            HStack(spacing: 6) {
                                                Image(systemName: cat.iconName)
                                                    .font(.system(size: 12))
                                                Text(cat.rawValue)
                                                    .font(.system(size: 13, weight: isSel ? .bold : .medium))
                                            }
                                            .foregroundColor(isSel ? .black : Theme.textDark)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(isSel ? AnyShapeStyle(Theme.brandGreen) : AnyShapeStyle(Theme.surfaceWhite))
                                            .clipShape(Capsule())
                                            .overlay(
                                                Capsule().stroke(isSel ? Color.clear : Theme.cardBorder, lineWidth: 1)
                                            )
                                            .shadow(color: isSel ? Theme.brandGreen.opacity(0.35) : Color.clear, radius: 4, x: 0, y: 1)
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }

                        // Top Trending Audiobooks Section (Elevated Cards with Real Covers)
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Popular Audiobooks")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(Theme.textDark)
                                Spacer()
                                NavigationLink(destination: ExploreSearchView()) {
                                    Text("See All")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(Theme.brandGreen)
                                }
                            }
                            .padding(.horizontal, 20)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
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
                                                .frame(width: 145, height: 145)

                                                VStack(alignment: .leading, spacing: 3) {
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
                                                        if !book.catalogSource.isEmpty {
                                                            Text(book.catalogSource)
                                                                .font(.system(size: 10))
                                                                .foregroundColor(Theme.textMuted)
                                                                .lineLimit(1)
                                                        }
                                                    }
                                                }
                                                .frame(width: 145, alignment: .leading)
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
                        }

                        // Extra bottom padding to clear the floating mini player and dock completely
                        Spacer(minLength: 160)
                    }
                }
            }
            .navigationBarHidden(true)
            .refreshable {
                await repository.fetchRemoteAudiobooks()
            }
        }
    }
}
