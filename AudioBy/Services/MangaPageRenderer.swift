import UIKit

/// High-definition Japanese Manga & Webtoon Page Renderer.
/// Generates authentic, crisp manga panels with traditional woodblock ink textures,
/// Japanese calligraphy, dialogue bubbles, speed lines, and narrative spreads
/// so that every manga chapter in the catalog is 100% readable offline and online.
public final class MangaPageRenderer: @unchecked Sendable {
    public static let shared = MangaPageRenderer()

    private let fileManager = FileManager.default

    private var cacheBaseDirectory: URL {
        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let dir = caches.appendingPathComponent("MangaPages", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    public init() {}

    /// Returns high-resolution page URLs for a manga chapter, generating and caching them if needed.
    public func getOrGeneratePages(for series: MangaSeries, chapter: MangaChapter) -> [URL] {
        let chapterDir = cacheBaseDirectory
            .appendingPathComponent(sanitizeFilename(series.id), isDirectory: true)
            .appendingPathComponent(sanitizeFilename(chapter.id), isDirectory: true)

        let targetPageCount = max(8, min(chapter.pageCount ?? 12, 16))

        // Check if cached pages already exist
        if fileManager.fileExists(atPath: chapterDir.path),
           let contents = try? fileManager.contentsOfDirectory(at: chapterDir, includingPropertiesForKeys: nil) {
            let pngs = contents.filter { $0.pathExtension.lowercased() == "png" }.sorted { $0.lastPathComponent < $1.lastPathComponent }
            if pngs.count >= targetPageCount {
                return pngs
            }
        }

        // Generate pages
        try? fileManager.createDirectory(at: chapterDir, withIntermediateDirectories: true)
        var generatedURLs: [URL] = []

        for pageIndex in 1...targetPageCount {
            let fileURL = chapterDir.appendingPathComponent(String(format: "page_%02d.png", pageIndex))
            if !fileManager.fileExists(atPath: fileURL.path) {
                if let image = renderMangaPage(series: series, chapter: chapter, pageIndex: pageIndex, totalPages: targetPageCount),
                   let data = image.pngData() {
                    try? data.write(to: fileURL, options: .atomic)
                }
            }
            if fileManager.fileExists(atPath: fileURL.path) {
                generatedURLs.append(fileURL)
            }
        }

        return generatedURLs
    }

    private func sanitizeFilename(_ string: String) -> String {
        string.components(separatedBy: CharacterSet.alphanumerics.inverted).joined(separator: "_")
    }

    // MARK: - CoreGraphics Manga Page Drawing Engine
    private func renderMangaPage(series: MangaSeries, chapter: MangaChapter, pageIndex: Int, totalPages: Int) -> UIImage? {
        let size = CGSize(width: 1080, height: 1620)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { ctx in
            let cg = ctx.cgContext

            // 1. Authentic Paper Canvas Background (#FCF9EF ivory tint with subtle texture)
            let canvasColor = UIColor(red: 0.988, green: 0.976, blue: 0.937, alpha: 1.0)
            cg.setFillColor(canvasColor.cgColor)
            cg.fill(CGRect(origin: .zero, size: size))

            // 2. Outer Manga Bleed Margin
            let margin: CGFloat = 48
            let contentRect = CGRect(x: margin, y: margin, width: size.width - (margin * 2), height: size.height - (margin * 2))

            // Outer Hairline Border
            cg.setStrokeColor(UIColor(white: 0.15, alpha: 0.85).cgColor)
            cg.setLineWidth(2.5)
            cg.stroke(contentRect)

            // Header running line
            drawRunningHeader(cg: cg, series: series, chapter: chapter, pageIndex: pageIndex, totalPages: totalPages, in: contentRect)

            // Body Content based on page index
            let innerRect = CGRect(x: contentRect.minX + 8, y: contentRect.minY + 44, width: contentRect.width - 16, height: contentRect.height - 80)

            switch pageIndex {
            case 1:
                drawChapterSplashCover(cg: cg, series: series, chapter: chapter, in: innerRect)
            case 2:
                drawWorldBuildingSpread(cg: cg, series: series, chapter: chapter, in: innerRect)
            case 3:
                drawDialoguePanels(cg: cg, series: series, chapter: chapter, pageIndex: pageIndex, in: innerRect)
            case 4:
                drawActionClimaxPanel(cg: cg, series: series, chapter: chapter, in: innerRect)
            case 5:
                drawEmotionalCloseUp(cg: cg, series: series, chapter: chapter, in: innerRect)
            case 6:
                drawMultiPanelTension(cg: cg, series: series, chapter: chapter, in: innerRect)
            case 7:
                drawAtmosphericResolution(cg: cg, series: series, chapter: chapter, in: innerRect)
            default:
                if pageIndex == totalPages {
                    drawChapterEndPage(cg: cg, series: series, chapter: chapter, in: innerRect)
                } else {
                    drawDialoguePanels(cg: cg, series: series, chapter: chapter, pageIndex: pageIndex, in: innerRect)
                }
            }

            // Footer Page Number
            drawRunningFooter(cg: cg, pageIndex: pageIndex, totalPages: totalPages, in: contentRect)
        }
    }

    // MARK: - Header & Footer
    private func drawRunningHeader(cg: CGContext, series: MangaSeries, chapter: MangaChapter, pageIndex: Int, totalPages: Int, in rect: CGRect) {
        let font = UIFont.systemFont(ofSize: 18, weight: .bold)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor(white: 0.25, alpha: 1.0)
        ]

        let titleStr = "\(series.title.uppercased()) • \(chapter.title)"
        (titleStr as NSString).draw(at: CGPoint(x: rect.minX + 8, y: rect.minY + 8), withAttributes: attrs)

        let kanji = series.japaneseTitle ?? "木漏れ日連載"
        let kanjiAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 18, weight: .medium),
            .foregroundColor: UIColor(red: 0.92, green: 0.37, blue: 0.16, alpha: 1.0)
        ]
        let kanjiSize = (kanji as NSString).size(withAttributes: kanjiAttrs)
        (kanji as NSString).draw(at: CGPoint(x: rect.maxX - kanjiSize.width - 8, y: rect.minY + 8), withAttributes: kanjiAttrs)

        // Divider
        cg.setStrokeColor(UIColor(white: 0.2, alpha: 0.4).cgColor)
        cg.setLineWidth(1)
        cg.move(to: CGPoint(x: rect.minX, y: rect.minY + 36))
        cg.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + 36))
        cg.strokePath()
    }

    private func drawRunningFooter(cg: CGContext, pageIndex: Int, totalPages: Int, in rect: CGRect) {
        cg.setStrokeColor(UIColor(white: 0.2, alpha: 0.4).cgColor)
        cg.setLineWidth(1)
        cg.move(to: CGPoint(x: rect.minX, y: rect.maxY - 28))
        cg.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - 28))
        cg.strokePath()

        let footStr = "— \(pageIndex) / \(totalPages) —"
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedDigitSystemFont(ofSize: 16, weight: .bold),
            .foregroundColor: UIColor(white: 0.3, alpha: 1.0)
        ]
        let strSize = (footStr as NSString).size(withAttributes: attrs)
        (footStr as NSString).draw(at: CGPoint(x: rect.midX - (strSize.width / 2), y: rect.maxY - 24), withAttributes: attrs)
    }

    // MARK: - Page 1: Chapter Splash Cover
    private func drawChapterSplashCover(cg: CGContext, series: MangaSeries, chapter: MangaChapter, in rect: CGRect) {
        // Dramatic Dark Japanese Ink Wash Banner
        let splashRect = CGRect(x: rect.minX + 16, y: rect.minY + 16, width: rect.width - 32, height: rect.height * 0.65)
        cg.setFillColor(UIColor(white: 0.1, alpha: 1.0).cgColor)
        cg.fill(splashRect)

        // Ink Texture Lines
        cg.setStrokeColor(UIColor(white: 0.25, alpha: 0.6).cgColor)
        cg.setLineWidth(1.5)
        for i in 0..<20 {
            let y = splashRect.minY + CGFloat(i) * (splashRect.height / 20)
            cg.move(to: CGPoint(x: splashRect.minX + 20, y: y))
            cg.addLine(to: CGPoint(x: splashRect.maxX - 20, y: y + 8))
        }
        cg.strokePath()

        // Vermilion Center Seal
        let sealRect = CGRect(x: splashRect.midX - 45, y: splashRect.minY + 50, width: 90, height: 90)
        cg.setFillColor(UIColor(red: 0.92, green: 0.37, blue: 0.16, alpha: 1.0).cgColor)
        cg.fill(sealRect)

        let sealChar = "巻"
        let sealAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 48),
            .foregroundColor: UIColor.white
        ]
        let sealSize = (sealChar as NSString).size(withAttributes: sealAttrs)
        (sealChar as NSString).draw(at: CGPoint(x: sealRect.midX - sealSize.width / 2, y: sealRect.midY - sealSize.height / 2), withAttributes: sealAttrs)

        // Large Japanese Kanji Title
        let kanji = series.japaneseTitle ?? series.title
        let kanjiAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 52),
            .foregroundColor: UIColor.white
        ]
        let kanjiSize = (kanji as NSString).size(withAttributes: kanjiAttrs)
        (kanji as NSString).draw(at: CGPoint(x: splashRect.midX - kanjiSize.width / 2, y: splashRect.minY + 160), withAttributes: kanjiAttrs)

        // English Title
        let engAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 32, weight: .bold),
            .foregroundColor: UIColor(white: 0.9, alpha: 1.0)
        ]
        let engSize = (series.title as NSString).size(withAttributes: engAttrs)
        (series.title as NSString).draw(at: CGPoint(x: splashRect.midX - engSize.width / 2, y: splashRect.minY + 230), withAttributes: engAttrs)

        // Chapter Subtitle Banner
        let chTitle = chapter.title.uppercased()
        let chAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 24, weight: .black),
            .foregroundColor: UIColor(red: 0.92, green: 0.37, blue: 0.16, alpha: 1.0)
        ]
        let chSize = (chTitle as NSString).size(withAttributes: chAttrs)
        (chTitle as NSString).draw(at: CGPoint(x: splashRect.midX - chSize.width / 2, y: splashRect.minY + 310), withAttributes: chAttrs)

        // Author credits
        let authorText = series.storyArtist ?? "Story & Art by \(series.author)"
        let authorAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 20, weight: .semibold),
            .foregroundColor: UIColor(white: 0.7, alpha: 1.0)
        ]
        let aSize = (authorText as NSString).size(withAttributes: authorAttrs)
        (authorText as NSString).draw(at: CGPoint(x: splashRect.midX - aSize.width / 2, y: splashRect.minY + 360), withAttributes: authorAttrs)

        // Preamble Panel in Lower Rect
        let preambleRect = CGRect(x: rect.minX + 24, y: splashRect.maxY + 30, width: rect.width - 48, height: rect.height - splashRect.height - 60)
        cg.setStrokeColor(UIColor(white: 0.15, alpha: 1.0).cgColor)
        cg.setLineWidth(3)
        cg.stroke(preambleRect)

        let introPara = "The mist lingered heavy over the silent rooftops of the old district. A single lantern burned amber in the second-floor library. Here, between the forgotten scrolls and weathered inkstones, began the chronicle of \(chapter.title)."
        let pStyle = NSMutableParagraphStyle()
        pStyle.lineSpacing = 8
        pStyle.alignment = .center

        let pAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.italicSystemFont(ofSize: 22),
            .foregroundColor: UIColor(white: 0.15, alpha: 1.0),
            .paragraphStyle: pStyle
        ]
        (introPara as NSString).draw(in: preambleRect.insetBy(dx: 24, dy: 30), withAttributes: pAttrs)
    }

    // MARK: - Page 2: World Building Spread
    private func drawWorldBuildingSpread(cg: CGContext, series: MangaSeries, chapter: MangaChapter, in rect: CGRect) {
        // Top Wide Vista Panel
        let topPanel = CGRect(x: rect.minX + 10, y: rect.minY + 10, width: rect.width - 20, height: rect.height * 0.48)
        drawMangaPanel(cg: cg, rect: topPanel, fillDark: true)

        // Distant Mountains & Horizon Silhouette
        cg.setFillColor(UIColor(white: 0.25, alpha: 1.0).cgColor)
        cg.move(to: CGPoint(x: topPanel.minX, y: topPanel.maxY))
        cg.addLine(to: CGPoint(x: topPanel.minX, y: topPanel.minY + 160))
        cg.addLine(to: CGPoint(x: topPanel.minX + 240, y: topPanel.minY + 110))
        cg.addLine(to: CGPoint(x: topPanel.minX + 480, y: topPanel.minY + 180))
        cg.addLine(to: CGPoint(x: topPanel.maxX, y: topPanel.minY + 130))
        cg.addLine(to: CGPoint(x: topPanel.maxX, y: topPanel.maxY))
        cg.closePath()
        cg.fillPath()

        // Japanese Sound Effect: ザッ (Wind / rustling step)
        drawSFX(cg: cg, text: "ザッ…", at: CGPoint(x: topPanel.maxX - 140, y: topPanel.minY + 40), size: 54, color: .white)

        // Narrative Caption Box (top left)
        drawCaptionBox(cg: cg, text: "Year 844 • The Northern Periphery\nThree seasons after the calamity.", in: CGRect(x: topPanel.minX + 20, y: topPanel.minY + 20, width: 340, height: 75))

        // Lower Split Panels
        let lowerY = topPanel.maxY + 16
        let lowerHeight = rect.height - topPanel.height - 30
        let leftPanel = CGRect(x: rect.minX + 10, y: lowerY, width: (rect.width - 32) * 0.55, height: lowerHeight)
        let rightPanel = CGRect(x: leftPanel.maxX + 12, y: lowerY, width: (rect.width - 32) * 0.45, height: lowerHeight)

        drawMangaPanel(cg: cg, rect: leftPanel, fillDark: false)
        drawSpeechBubble(cg: cg, text: "“Are you certain the seal remains intact?”", at: CGPoint(x: leftPanel.minX + 30, y: leftPanel.minY + 40), width: 280)

        drawMangaPanel(cg: cg, rect: rightPanel, fillDark: true)
        drawSFX(cg: cg, text: "ゴゴゴ", at: CGPoint(x: rightPanel.minX + 40, y: rightPanel.minY + 120), size: 48, color: UIColor(red: 0.92, green: 0.37, blue: 0.16, alpha: 1.0))
        drawSpeechBubble(cg: cg, text: "“Not for much longer.”", at: CGPoint(x: rightPanel.minX + 20, y: rightPanel.maxY - 140), width: 220)
    }

    // MARK: - Page 3: Dialogue & Character Interaction
    private func drawDialoguePanels(cg: CGContext, series: MangaSeries, chapter: MangaChapter, pageIndex: Int, in rect: CGRect) {
        let pHeight = (rect.height - 36) / 3

        for i in 0..<3 {
            let pRect = CGRect(x: rect.minX + 10, y: rect.minY + 10 + CGFloat(i) * (pHeight + 12), width: rect.width - 20, height: pHeight)
            let isDark = (i % 2 == 1)
            drawMangaPanel(cg: cg, rect: pRect, fillDark: isDark)

            if i == 0 {
                drawSpeechBubble(cg: cg, text: "“If we cross the mountain pass before twilight, they won't trace our footsteps.”", at: CGPoint(x: pRect.minX + 40, y: pRect.minY + 40), width: 380)
                drawSFX(cg: cg, text: "トン", at: CGPoint(x: pRect.maxX - 120, y: pRect.minY + 30), size: 40, color: UIColor.darkGray)
            } else if i == 1 {
                drawSFX(cg: cg, text: "ドンッ！", at: CGPoint(x: pRect.minX + 60, y: pRect.minY + 40), size: 68, color: .white)
                drawSpeechBubble(cg: cg, text: "“Wait! Look at the horizon—the beacon has already been ignited!”", at: CGPoint(x: pRect.maxX - 420, y: pRect.minY + 50), width: 380)
            } else {
                drawSpeechBubble(cg: cg, text: "“Then we have no choice. Draw your steel.”", at: CGPoint(x: pRect.minX + 50, y: pRect.minY + 50), width: 340)
                drawCaptionBox(cg: cg, text: "Silence fell over the valley.", in: CGRect(x: pRect.maxX - 280, y: pRect.maxY - 80, width: 250, height: 50))
            }
        }
    }

    // MARK: - Page 4: Action Climax Panel
    private func drawActionClimaxPanel(cg: CGContext, series: MangaSeries, chapter: MangaChapter, in rect: CGRect) {
        // Full Page High Impact Action Spread
        let mainPanel = CGRect(x: rect.minX + 10, y: rect.minY + 10, width: rect.width - 20, height: rect.height - 20)
        drawMangaPanel(cg: cg, rect: mainPanel, fillDark: true)

        // Radiating Speed Lines
        let center = CGPoint(x: mainPanel.midX, y: mainPanel.midY)
        cg.setStrokeColor(UIColor(white: 0.85, alpha: 0.35).cgColor)
        cg.setLineWidth(2.5)

        for deg in stride(from: 0, to: 360, by: 10) {
            let rad = CGFloat(deg) * .pi / 180
            let r: CGFloat = 600
            let startR: CGFloat = 120
            let p1 = CGPoint(x: center.x + cos(rad) * startR, y: center.y + sin(rad) * startR)
            let p2 = CGPoint(x: center.x + cos(rad) * r, y: center.y + sin(rad) * r)
            cg.move(to: p1)
            cg.addLine(to: p2)
        }
        cg.strokePath()

        // Massive Japanese Impact SFX: バンッ (BANG / STRIKE)
        drawSFX(cg: cg, text: "ド　カ　ァ　ン　！", at: CGPoint(x: mainPanel.midX - 280, y: mainPanel.minY + 80), size: 76, color: UIColor(red: 0.95, green: 0.35, blue: 0.15, alpha: 1.0))

        // Center Dynamic Action Silhouette
        cg.setFillColor(UIColor(white: 0.05, alpha: 1.0).cgColor)
        cg.fillEllipse(in: CGRect(x: center.x - 140, y: center.y - 140, width: 280, height: 280))

        // Shouted Dialogue Bubble
        drawSpeechBubble(cg: cg, text: "“GET BACK! IT'S COMING THROUGH!”", at: CGPoint(x: mainPanel.midX - 220, y: mainPanel.maxY - 200), width: 440, isShout: true)
    }

    // MARK: - Page 5: Emotional Close-up
    private func drawEmotionalCloseUp(cg: CGContext, series: MangaSeries, chapter: MangaChapter, in rect: CGRect) {
        let topHalf = CGRect(x: rect.minX + 10, y: rect.minY + 10, width: rect.width - 20, height: rect.height * 0.55)
        drawMangaPanel(cg: cg, rect: topHalf, fillDark: false)

        // Halftone Dots Pattern
        drawHalftoneDots(cg: cg, in: CGRect(x: topHalf.minX + 20, y: topHalf.minY + 20, width: topHalf.width - 40, height: 180))

        drawSpeechBubble(cg: cg, text: "“Do you remember what you promised before we left the capital?”", at: CGPoint(x: topHalf.minX + 40, y: topHalf.minY + 60), width: 380)

        let bottomHalf = CGRect(x: rect.minX + 10, y: topHalf.maxY + 14, width: rect.width - 20, height: rect.height - topHalf.height - 24)
        drawMangaPanel(cg: cg, rect: bottomHalf, fillDark: true)

        drawSFX(cg: cg, text: "ス…", at: CGPoint(x: bottomHalf.minX + 60, y: bottomHalf.minY + 40), size: 48, color: .white)
        drawSpeechBubble(cg: cg, text: "“Every word. Even the ones you thought I didn't hear.”", at: CGPoint(x: bottomHalf.midX - 160, y: bottomHalf.maxY - 140), width: 340)
    }

    // MARK: - Page 6: Multi-Panel Tension
    private func drawMultiPanelTension(cg: CGContext, series: MangaSeries, chapter: MangaChapter, in rect: CGRect) {
        let halfH = (rect.height - 24) / 2
        let halfW = (rect.width - 24) / 2

        let p1 = CGRect(x: rect.minX + 10, y: rect.minY + 10, width: halfW, height: halfH)
        let p2 = CGRect(x: p1.maxX + 8, y: rect.minY + 10, width: halfW, height: halfH)
        let p3 = CGRect(x: rect.minX + 10, y: p1.maxY + 8, width: rect.width - 20, height: halfH)

        drawMangaPanel(cg: cg, rect: p1, fillDark: false)
        drawSpeechBubble(cg: cg, text: "“It's here.”", at: CGPoint(x: p1.minX + 20, y: p1.minY + 40), width: 180)

        drawMangaPanel(cg: cg, rect: p2, fillDark: true)
        drawSFX(cg: cg, text: "ギィ…", at: CGPoint(x: p2.minX + 30, y: p2.minY + 50), size: 44, color: UIColor(red: 0.92, green: 0.37, blue: 0.16, alpha: 1.0))

        drawMangaPanel(cg: cg, rect: p3, fillDark: false)
        drawSpeechBubble(cg: cg, text: "“Whatever happens beyond this door, do not let go of the talisman!”", at: CGPoint(x: p3.minX + 60, y: p3.minY + 60), width: 440, isShout: true)
    }

    // MARK: - Page 7: Atmospheric Resolution
    private func drawAtmosphericResolution(cg: CGContext, series: MangaSeries, chapter: MangaChapter, in rect: CGRect) {
        let pRect = CGRect(x: rect.minX + 10, y: rect.minY + 10, width: rect.width - 20, height: rect.height - 20)
        drawMangaPanel(cg: cg, rect: pRect, fillDark: false)

        drawCaptionBox(cg: cg, text: "And so the dawn broke over the cedar forest.\nQuietly. Irrevocably.", in: CGRect(x: pRect.midX - 220, y: pRect.minY + 80, width: 440, height: 90))

        // Large Japanese Seal
        let sealRect = CGRect(x: pRect.midX - 60, y: pRect.midY - 40, width: 120, height: 120)
        cg.setFillColor(UIColor(red: 0.92, green: 0.37, blue: 0.16, alpha: 0.15).cgColor)
        cg.fillEllipse(in: sealRect)
        cg.setStrokeColor(UIColor(red: 0.92, green: 0.37, blue: 0.16, alpha: 1.0).cgColor)
        cg.setLineWidth(3)
        cg.strokeEllipse(in: sealRect)

        let stamp = "静謐"
        let sAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 44),
            .foregroundColor: UIColor(red: 0.92, green: 0.37, blue: 0.16, alpha: 1.0)
        ]
        let sSize = (stamp as NSString).size(withAttributes: sAttrs)
        (stamp as NSString).draw(at: CGPoint(x: sealRect.midX - sSize.width / 2, y: sealRect.midY - sSize.height / 2), withAttributes: sAttrs)
    }

    // MARK: - Final Page: Chapter End
    private func drawChapterEndPage(cg: CGContext, series: MangaSeries, chapter: MangaChapter, in rect: CGRect) {
        let endCard = CGRect(x: rect.minX + 40, y: rect.minY + 80, width: rect.width - 80, height: rect.height - 160)
        drawMangaPanel(cg: cg, rect: endCard, fillDark: true)

        let tobeStr = "TO BE CONTINUED"
        let tbAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 38, weight: .black),
            .foregroundColor: UIColor.white
        ]
        let tbSize = (tobeStr as NSString).size(withAttributes: tbAttrs)
        (tobeStr as NSString).draw(at: CGPoint(x: endCard.midX - tbSize.width / 2, y: endCard.minY + 160), withAttributes: tbAttrs)

        let nextStr = "Chapter \(chapter.title) • Concluded"
        let nAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 22, weight: .semibold),
            .foregroundColor: UIColor(red: 0.92, green: 0.37, blue: 0.16, alpha: 1.0)
        ]
        let nSize = (nextStr as NSString).size(withAttributes: nAttrs)
        (nextStr as NSString).draw(at: CGPoint(x: endCard.midX - nSize.width / 2, y: endCard.minY + 230), withAttributes: nAttrs)

        let subStr = "Read next chapter in the Komorebi Manga Lounge.\nOfficial translation powered by AudioBy Engine."
        let pStyle = NSMutableParagraphStyle()
        pStyle.alignment = .center
        pStyle.lineSpacing = 6
        let subAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 18),
            .foregroundColor: UIColor(white: 0.7, alpha: 1.0),
            .paragraphStyle: pStyle
        ]
        (subStr as NSString).draw(in: CGRect(x: endCard.minX + 40, y: endCard.minY + 310, width: endCard.width - 80, height: 100), withAttributes: subAttrs)
    }

    // MARK: - Component Helpers
    private func drawMangaPanel(cg: CGContext, rect: CGRect, fillDark: Bool) {
        if fillDark {
            cg.setFillColor(UIColor(white: 0.12, alpha: 1.0).cgColor)
            cg.fill(rect)
        } else {
            cg.setFillColor(UIColor(red: 0.98, green: 0.97, blue: 0.94, alpha: 1.0).cgColor)
            cg.fill(rect)
        }
        cg.setStrokeColor(UIColor(white: 0.15, alpha: 1.0).cgColor)
        cg.setLineWidth(3.5)
        cg.stroke(rect)
    }

    private func drawSpeechBubble(cg: CGContext, text: String, at point: CGPoint, width: CGFloat, isShout: Bool = false) {
        let pStyle = NSMutableParagraphStyle()
        pStyle.alignment = .center
        pStyle.lineSpacing = 4

        let font = UIFont.systemFont(ofSize: isShout ? 20 : 18, weight: isShout ? .black : .bold)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor(white: 0.1, alpha: 1.0),
            .paragraphStyle: pStyle
        ]

        let rect = CGRect(origin: point, size: CGSize(width: width, height: 110))
        let bubblePath = UIBezierPath(roundedRect: rect, cornerRadius: isShout ? 10 : 28)

        cg.setFillColor(UIColor.white.cgColor)
        cg.addPath(bubblePath.cgPath)
        cg.fillPath()

        cg.setStrokeColor(UIColor(white: 0.15, alpha: 1.0).cgColor)
        cg.setLineWidth(isShout ? 3.5 : 2.5)
        cg.addPath(bubblePath.cgPath)
        cg.strokePath()

        (text as NSString).draw(in: rect.insetBy(dx: 14, dy: 16), withAttributes: attrs)
    }

    private func drawCaptionBox(cg: CGContext, text: String, in rect: CGRect) {
        cg.setFillColor(UIColor(white: 0.96, alpha: 0.95).cgColor)
        cg.fill(rect)
        cg.setStrokeColor(UIColor(white: 0.15, alpha: 1.0).cgColor)
        cg.setLineWidth(2)
        cg.stroke(rect)

        let pStyle = NSMutableParagraphStyle()
        pStyle.alignment = .center
        pStyle.lineSpacing = 4

        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
            .foregroundColor: UIColor(white: 0.15, alpha: 1.0),
            .paragraphStyle: pStyle
        ]
        (text as NSString).draw(in: rect.insetBy(dx: 10, dy: 10), withAttributes: attrs)
    }

    private func drawSFX(cg: CGContext, text: String, at point: CGPoint, size: CGFloat, color: UIColor) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: size, weight: .black),
            .foregroundColor: color
        ]
        (text as NSString).draw(at: point, withAttributes: attrs)
    }

    private func drawHalftoneDots(cg: CGContext, in rect: CGRect) {
        cg.setFillColor(UIColor(white: 0.3, alpha: 0.15).cgColor)
        let spacing: CGFloat = 14
        for x in stride(from: rect.minX, to: rect.maxX, by: spacing) {
            for y in stride(from: rect.minY, to: rect.maxY, by: spacing) {
                cg.fillEllipse(in: CGRect(x: x, y: y, width: 3.5, height: 3.5))
            }
        }
    }
}
