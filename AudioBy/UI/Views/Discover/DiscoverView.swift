import SwiftUI

public struct DiscoverView: View {
    @Bindable var repository = AudiobookRepository.shared
    @Bindable var playerService = AudioPlayerService.shared

    public init() {}

    public var body: some View {
        LearningPathView()
    }
}
