import SwiftUI

public struct AddBookmarkSheet: View {
    @Environment(\.dismiss) private var dismiss
    public let timestamp: TimeInterval
    public let chapterTitle: String
    public let onSave: (String) -> Void

    @State private var note: String = ""

    public var body: some View {
        NavigationStack {
            ZStack {
                Theme.appBackground.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(chapterTitle)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)

                        HStack {
                            Image(systemName: "bookmark.fill")
                                .foregroundColor(Theme.brandGreen)
                            Text(formatTime(timestamp))
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(Theme.brandGreen)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 14)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Note or Key Takeaway (Optional)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Theme.textMuted)

                        TextField("Add key insights, quotes, or notes...", text: $note, axis: .vertical)
                            .lineLimit(4...6)
                            .padding(14)
                            .background(Theme.surfaceWhite)
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Theme.cardBorder, lineWidth: 1)
                            )
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 20)

                    Spacer()
                }
            }
            .navigationTitle("Add Bookmark")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Theme.textMuted)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onSave(note)
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(Theme.brandGreen)
                }
            }
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let total = Int(time)
        let mins = total / 60
        let secs = total % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
