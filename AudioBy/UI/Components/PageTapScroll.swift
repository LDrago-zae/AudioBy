import SwiftUI
import UIKit

/// Finds the enclosing UIScrollView so taps on the screen edges can page it.
private struct ScrollFinder: UIViewRepresentable {
    let onFound: (UIScrollView) -> Void
    func makeUIView(context: Context) -> UIView { UIView() }
    func updateUIView(_ view: UIView, context: Context) {
        DispatchQueue.main.async {
            var v: UIView? = view
            while let cur = v {
                if let s = cur as? UIScrollView { onFound(s); return }
                v = cur.superview
            }
        }
    }
}

private final class ScrollBox { weak var scroll: UIScrollView? }

private struct PageTapScrollModifier: ViewModifier {
    var onCenterTap: () -> Void
    @State private var box = ScrollBox()

    func body(content: Content) -> some View {
        content
            .background(ScrollFinder { box.scroll = $0 })
            .simultaneousGesture(
                SpatialTapGesture().onEnded { value in
                    let w = UIScreen.main.bounds.width
                    if value.location.x < w * 0.3 {
                        page(-1)
                    } else if value.location.x > w * 0.7 {
                        page(1)
                    } else {
                        onCenterTap()
                    }
                }
            )
    }

    private func page(_ dir: CGFloat) {
        guard let s = box.scroll else { return }
        let step = s.bounds.height * 0.88
        let maxY = max(0, s.contentSize.height - s.bounds.height + s.adjustedContentInset.bottom)
        let minY = -s.adjustedContentInset.top
        let y = min(maxY, max(minY, s.contentOffset.y + dir * step))
        s.setContentOffset(CGPoint(x: s.contentOffset.x, y: y), animated: true)
    }
}

extension View {
    /// Left 30% of the screen = previous page, right 30% = next page, middle = `onCenterTap`.
    func pageTapScroll(onCenterTap: @escaping () -> Void = {}) -> some View {
        modifier(PageTapScrollModifier(onCenterTap: onCenterTap))
    }
}
