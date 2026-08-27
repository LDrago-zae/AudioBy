import SwiftUI
import UniformTypeIdentifiers

struct PDFImportPresenter: ViewModifier {
    @Binding var isPresented: Bool
    @Binding var showingPaywall: Bool
    @Bindable var entitlements = EntitlementService.shared
    @Bindable var repository = AudiobookRepository.shared
    @State private var showFilePicker = false
    @State private var importError: String?
    @State private var isImporting = false

    func body(content: Content) -> some View {
        content
            .onChange(of: isPresented) { _, newValue in
                guard newValue else { return }
                isPresented = false
                if entitlements.canImportPDF {
                    showFilePicker = true
                } else {
                    showingPaywall = true
                }
            }
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [.pdf],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    importPDF(url)
                case .failure(let error):
                    importError = error.localizedDescription
                }
            }
            .alert("Could not import PDF", isPresented: Binding(
                get: { importError != nil },
                set: { if !$0 { importError = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(importError ?? "")
            }
            .overlay {
                if isImporting {
                    ProgressView("Extracting text...")
                        .padding(20)
                        .background(Theme.surfaceWhite)
                        .cornerRadius(16)
                }
            }
    }

    private func importPDF(_ url: URL) {
        isImporting = true
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let book = try UserImportService.shared.importPDF(from: url)
                DispatchQueue.main.async {
                    repository.upsertImportedBook(book)
                    isImporting = false
                }
            } catch {
                DispatchQueue.main.async {
                    isImporting = false
                    importError = error.localizedDescription
                }
            }
        }
    }
}
