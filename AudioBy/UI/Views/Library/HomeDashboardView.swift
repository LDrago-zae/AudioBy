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
                                Text(timeOfDayGreeting)
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(Theme.textMuted)

                                Text("Discover Audiobooks")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(Theme.textDark)
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
                                    .foregroundColor(Color(red: 0.85, green: 0.70, blue: 0.60))
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white.opacity(0.2), lineWidth: 2)
                                    )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

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

                        // Featured Hero Spotlight Carousel
                        if let hero = repository.featuredHeroBooks.first {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("FEATURED SPOTLIGHT")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(Theme.brandGreen)
                                        .tracking(1.1)
                                    Spacer()
                                    HStack(spacing: 4) {
                                        Image(systemName: "sparkles")
                                            .font(.system(size: 11))
                                            .foregroundColor(.yellow)
                                        Text("LibriVox")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(Theme.textMuted)
                                    }
                                }
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

                        // Continue Listening Section
                        if !repository.continueListeningBooks.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Continue Listening")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(Theme.textDark)
                                    .padding(.horizontal, 20)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 14) {
                                        ForEach(repository.continueListeningBooks) { book in
                                            Button {
                                                playerService.playAudiobook(book, chapterIndex: book.currentChapterIndex, autoPlay: true)
                                            } label: {
                                                HStack(spacing: 12) {
                                                    CoverArtView(
                                                        title: book.title,
                                                        author: book.author,
                                                        gradientHexes: book.coverGradientColors,
                                                        coverImageURL: book.coverImageURL,
                                                        cornerRadius: 12,
                                                        shadowRadius: 4
                                                    )
                                                    .frame(width: 52, height: 52)

                                                    VStack(alignment: .leading, spacing: 4) {
                                                        Text(book.title)
                                                            .font(.system(size: 14, weight: .bold))
                                                            .foregroundColor(Theme.textDark)
                                                            .lineLimit(1)

                                                        Text(book.currentChapter?.title ?? "Chapter 1")
                                                            .font(.system(size: 12))
                                                            .foregroundColor(Theme.textMuted)
                                                            .lineLimit(1)

                                                        // Mini Progress Bar
                                                        GeometryReader { g in
                                                            ZStack(alignment: .leading) {
                                                                Capsule()
                                                                    .fill(Theme.surfaceSubtle)
                                                                    .frame(height: 4)
                                                                Capsule()
                                                                    .fill(Theme.brandGreen)
                                                                    .frame(width: max(0, CGFloat(book.progress) * g.size.width), height: 4)
                                                            }
                                                        }
                                                        .frame(height: 4)
                                                    }

                                                    Image(systemName: "play.circle.fill")
                                                        .font(.system(size: 26))
                                                        .foregroundColor(Theme.brandGreen)
                                                }
                                                .padding(12)
                                                .frame(width: 270)
                                                .background(Theme.surfaceWhite)
                                                .cornerRadius(16)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 16)
                                                        .stroke(Theme.cardBorder, lineWidth: 1)
                                                )
                                            }
                                        }
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

    private var timeOfDayGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good Morning," }
        if hour < 17 { return "Good Afternoon," }
        return "Good Evening,"
    }
}
