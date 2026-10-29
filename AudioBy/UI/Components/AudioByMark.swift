import SwiftUI

/// Manga speech bubble with sonic bars (use `.fill(style: FillStyle(eoFill: true))`).
public struct AudioByMark: Shape {
    public init() {}

    public func path(in rect: CGRect) -> Path {
        let sx = rect.width / 32
        let sy = rect.height / 32
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * sx, y: rect.minY + y * sy)
        }
        func r(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect {
            CGRect(x: rect.minX + x * sx, y: rect.minY + y * sy, width: w * sx, height: h * sy)
        }

        var path = Path()
        let cr: CGFloat = 3.8

        // Continuous bubble + tail silhouette
        path.move(to: p(5 + cr, 4.2))
        path.addLine(to: p(27 - cr, 4.2))
        path.addQuadCurve(to: p(30.8, 4.2 + cr), control: p(30.8, 4.2))
        path.addLine(to: p(30.8, 19.2 - cr))
        path.addQuadCurve(to: p(27 - cr, 23), control: p(30.8, 23))
        path.addLine(to: p(14.2, 23))
        path.addLine(to: p(8.2, 29.2))
        path.addLine(to: p(9.6, 23))
        path.addLine(to: p(5 + cr, 23))
        path.addQuadCurve(to: p(1.2, 19.2 - cr), control: p(1.2, 23))
        path.addLine(to: p(1.2, 4.2 + cr))
        path.addQuadCurve(to: p(5 + cr, 4.2), control: p(1.2, 4.2))
        path.closeSubpath()

        // Sonic bars (holes)
        path.addRect(r(9.6, 10.4, 3, 8.6))
        path.addRect(r(14.5, 8.2, 3, 10.8))
        path.addRect(r(19.4, 9.5, 3, 9.5))

        return path
    }
}
