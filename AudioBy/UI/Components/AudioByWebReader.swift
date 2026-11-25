import SwiftUI
import WebKit

/// In-app browser chrome for externally hosted chapters (MangaPlus, etc.).
/// Looks like AudioBy, not Safari.
public struct AudioByWebReader: View {
    public let url: URL
    public let title: String
    public var subtitle: String?

    @Environment(\.dismiss) private var dismiss
    @State private var pageTitle: String = ""
    @State private var isLoading = true
    @State private var canGoBack = false
    @State private var canGoForward = false
    @State private var progress: Double = 0
    @State private var webView = WKWebView(frame: .zero, configuration: AudioByWebReader.makeConfig())

    public init(url: URL, title: String, subtitle: String? = nil) {
        self.url = url
        self.title = title
        self.subtitle = subtitle
    }

    public var body: some View {
        VStack(spacing: 0) {
            topBar
            if isLoading || progress < 1 {
                GeometryReader { geo in
                    MangaTheme.vermilion
                        .frame(width: geo.size.width * max(progress, 0.05), height: 2)
                        .animation(.easeOut(duration: 0.2), value: progress)
                }
                .frame(height: 2)
                .background(MangaTheme.hairline)
            }
            WebViewHost(
                webView: webView,
                url: url,
                isLoading: $isLoading,
                canGoBack: $canGoBack,
                canGoForward: $canGoForward,
                progress: $progress,
                pageTitle: $pageTitle
            )
            bottomBar
        }
        .background(MangaTheme.surface.ignoresSafeArea())
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(MangaTheme.ink)
                    .frame(width: 36, height: 36)
                    .background(MangaTheme.surfaceLow, in: Circle())
                    .overlay(Circle().stroke(MangaTheme.hairline, lineWidth: 1))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(MangaTheme.ink)
                    .lineLimit(1)
                Text(subtitle ?? (pageTitle.isEmpty ? hostLabel : pageTitle))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(MangaTheme.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            Text("AudioBy")
                .font(.system(size: 10, weight: .bold))
                .tracking(0.6)
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(MangaTheme.vermilion, in: Capsule())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(MangaTheme.surfaceLow)
        .overlay(alignment: .bottom) {
            Rectangle().fill(MangaTheme.hairline).frame(height: 1)
        }
    }

    private var bottomBar: some View {
        HStack(spacing: 22) {
            Button { webView.goBack() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(canGoBack ? MangaTheme.ink : MangaTheme.secondary.opacity(0.4))
            }
            .disabled(!canGoBack)
            .buttonStyle(.plain)

            Button { webView.goForward() } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(canGoForward ? MangaTheme.ink : MangaTheme.secondary.opacity(0.4))
            }
            .disabled(!canGoForward)
            .buttonStyle(.plain)

            Button {
                webView.reload()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(MangaTheme.ink)
            }
            .buttonStyle(.plain)

            Spacer()

            Button { dismiss() } label: {
                Text("Back to library")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(MangaTheme.vermilion)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(MangaTheme.surfaceLow)
        .overlay(alignment: .top) {
            Rectangle().fill(MangaTheme.hairline).frame(height: 1)
        }
    }

    private var hostLabel: String {
        url.host?.replacingOccurrences(of: "www.", with: "") ?? "Reader"
    }

    private static func makeConfig() -> WKWebViewConfiguration {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        return config
    }
}

private struct WebViewHost: UIViewRepresentable {
    let webView: WKWebView
    let url: URL
    @Binding var isLoading: Bool
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    @Binding var progress: Double
    @Binding var pageTitle: String

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> WKWebView {
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.backgroundColor = .clear
        webView.isOpaque = false
        webView.addObserver(context.coordinator, forKeyPath: "estimatedProgress", options: .new, context: nil)
        webView.addObserver(context.coordinator, forKeyPath: "title", options: .new, context: nil)
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        uiView.removeObserver(coordinator, forKeyPath: "estimatedProgress")
        uiView.removeObserver(coordinator, forKeyPath: "title")
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebViewHost
        init(_ parent: WebViewHost) { self.parent = parent }

        override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
            if keyPath == "estimatedProgress" {
                parent.progress = parent.webView.estimatedProgress
            } else if keyPath == "title" {
                parent.pageTitle = parent.webView.title ?? ""
            }
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
            sync()
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
            parent.progress = 1
            sync()
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
            sync()
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
            sync()
        }

        private func sync() {
            parent.canGoBack = parent.webView.canGoBack
            parent.canGoForward = parent.webView.canGoForward
            parent.pageTitle = parent.webView.title ?? parent.pageTitle
        }
    }
}

public struct ExternalChapterRoute: Identifiable, Hashable {
    public let id = UUID()
    public let url: URL
    public let title: String
    public let subtitle: String?

    public init(url: URL, title: String, subtitle: String? = nil) {
        self.url = url
        self.title = title
        self.subtitle = subtitle
    }
}
