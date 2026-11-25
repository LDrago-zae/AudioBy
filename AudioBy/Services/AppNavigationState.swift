import SwiftUI

public enum AppSection: String, CaseIterable, Identifiable {
    case audiobooks = "Audiobooks"
    case manga = "Manga"
    case novels = "Light Novels"
    case activity = "Activity"
    case settings = "Settings"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .audiobooks: return "headphones"
        case .manga: return "book.pages.fill"
        case .novels: return "text.book.closed.fill"
        case .activity: return "flame.fill"
        case .settings: return "gearshape.fill"
        }
    }

    public var subtitle: String {
        switch self {
        case .audiobooks: return "Narration & Audiobooks"
        case .manga: return "Japanese Manga & Manhwa"
        case .novels: return "Serialized Fiction & E-Books"
        case .activity: return "Reading Stats & Streaks"
        case .settings: return "Preferences & Account"
        }
    }
}

public enum MangaSubTab: String, CaseIterable, Identifiable {
    case discover = "Discover"
    case browse = "Browse"
    case library = "My Library"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .discover: return "sparkles"
        case .browse: return "safari"
        case .library: return "books.vertical.fill"
        }
    }
}

@Observable
public final class AppNavigationState {
    public static let shared = AppNavigationState()

    public var currentSection: AppSection = .audiobooks
    public var isSidebarOpen: Bool = false
    public var mangaTab: MangaSubTab = .discover
    public var dockTab: DockTab = .home
    public var requestedLibraryShelf: LibraryShelf?

    // Modal states
    public var selectedMangaSeries: MangaSeries? = nil
    public var selectedNovelSeries: MangaSeries? = nil
    public var isPresentingImporter: Bool = false

    private init() {}

    public func openSidebar() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            isSidebarOpen = true
        }
    }

    public func closeSidebar() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            isSidebarOpen = false
        }
    }

    public func toggleSidebar() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            isSidebarOpen.toggle()
        }
    }

    public func openListeningShelf() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            currentSection = .audiobooks
            dockTab = .library
            requestedLibraryShelf = .inProgress
            isSidebarOpen = false
        }
    }

    public func switchTo(_ section: AppSection) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            currentSection = section
            isSidebarOpen = false
        }
    }
}

