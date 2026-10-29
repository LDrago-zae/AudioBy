import SwiftUI
import UIKit

public enum Theme {
    // Cream paper, stone, charcoal, and burnt orange.
    // #fffcf2  #ccc5b9  #403d39  #252422  #eb5e28

    public static let paper = Color(red: 1.0, green: 0.988, blue: 0.949)
    public static let stone = Color(red: 0.800, green: 0.773, blue: 0.725)
    public static let charcoal = Color(red: 0.251, green: 0.239, blue: 0.224)
    public static let ink = Color(red: 0.145, green: 0.141, blue: 0.133)
    public static let ember = Color(red: 0.922, green: 0.369, blue: 0.157)
    public static let emberDeep = Color(red: 0.729, green: 0.314, blue: 0.149)
    /// Ink on ember. Cream on ember fails body contrast.
    public static let onAccent = ink

    /// Fallback covers stay inside the palette. Cached catalog rows still store the old green pair.
    public static func coverHexes(seed: String, stored: [String] = []) -> [String] {
        let allowed: Set<String> = ["fffcf2", "ccc5b9", "403d39", "252422", "eb5e28", "ba5026"]
        let normalized = stored.map { hex in
            hex.trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "#", with: "")
                .lowercased()
        }
        if normalized.count >= 2, normalized.allSatisfy({ allowed.contains($0) }) {
            return stored
        }
        let pairs = [
            ["#252422", "#403d39"],
            ["#403d39", "#252422"],
            ["#252422", "#eb5e28"],
            ["#403d39", "#ba5026"]
        ]
        var hash = 5381
        for byte in seed.utf8 {
            hash = hash &* 33 &+ Int(byte)
        }
        return pairs[abs(hash) % pairs.count]
    }

    public static var appBackground: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.145, green: 0.141, blue: 0.133, alpha: 1.0)
                : UIColor(red: 0.945, green: 0.929, blue: 0.886, alpha: 1.0)
        })
    }

    public static var surfaceWhite: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.251, green: 0.239, blue: 0.224, alpha: 1.0)
                : UIColor(red: 1.0, green: 0.988, blue: 0.949, alpha: 1.0)
        })
    }

    public static var surfaceSubtle: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.196, green: 0.188, blue: 0.176, alpha: 1.0)
                : UIColor(red: 0.929, green: 0.914, blue: 0.871, alpha: 1.0)
        })
    }

    public static var surfaceDark: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.145, green: 0.141, blue: 0.133, alpha: 1.0)
                : UIColor(red: 0.251, green: 0.239, blue: 0.224, alpha: 1.0)
        })
    }

    public static var cardDark: Color {
        surfaceWhite
    }

    public static var cardBorder: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.08)
                : UIColor.black.withAlphaComponent(0.06)
        })
    }

    public static let brandGreen = ember
    public static let brandGreenContainer = emberDeep
    public static let brandGreenLight = ember
    public static let brandGreenDark = emberDeep

    public static let brandCyan = ember
    public static let brandCyanContainer = emberDeep

    public static let brandGold = ember

    // Aliases
    public static let accent = brandGreen
    public static let accentSecondary = brandCyan

    // MARK: - Dynamic Text Typography
    public static var textDark: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 1.0, green: 0.988, blue: 0.949, alpha: 1.0)
                : UIColor(red: 0.145, green: 0.141, blue: 0.133, alpha: 1.0)
        })
    }

    public static var textPrimary: Color {
        textDark
    }

    public static var textMuted: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.800, green: 0.773, blue: 0.725, alpha: 1.0)
                : UIColor(red: 0.251, green: 0.239, blue: 0.224, alpha: 1.0)
        })
    }

    public static var textLightMuted: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.800, green: 0.773, blue: 0.725, alpha: 1.0)
                : UIColor(red: 0.251, green: 0.239, blue: 0.224, alpha: 1.0)
        })
    }

    public static let textWhite = Color.white

    public static var textSecondary: Color {
        textMuted
    }

    // MARK: - Gradients
    public static let activeGreenGradient = LinearGradient(
        colors: [brandGreenLight, brandGreenContainer],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    public static let accentGradient = activeGreenGradient

    public static var darkCardGradient: LinearGradient {
        LinearGradient(
            colors: [
                surfaceWhite,
                surfaceSubtle
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Ink on paper, charcoal on ink, so the tab bar stays visible in both appearances.
    public static var dockBar: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.251, green: 0.239, blue: 0.224, alpha: 1.0)
                : UIColor(red: 0.145, green: 0.141, blue: 0.133, alpha: 1.0)
        })
    }

    public static var dockBackground: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.145, green: 0.141, blue: 0.133, alpha: 0.94)
                : UIColor(red: 1.0, green: 0.988, blue: 0.949, alpha: 0.94)
        })
    }

    // MARK: - Glass Surfaces & Shelf Tints
    public static let foundationShelfTint = Color(red: 0.922, green: 0.369, blue: 0.157, opacity: 0.35)
    public static let buildShelfTint = Color(red: 0.800, green: 0.773, blue: 0.725, opacity: 0.45)
    public static let proveShelfTint = Color(red: 0.251, green: 0.239, blue: 0.224, opacity: 0.35)
    
    public static var glassSurface: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.06)
                : UIColor.black.withAlphaComponent(0.04)
        })
    }
    public static var glassBorder: Color {
        cardBorder
    }

    // MARK: - Dark Matrix Palette
    public static let matrixBackground = ink
    public static let matrixCardBorder = Color.white.opacity(0.10)
    public static let matrixDotInactive = Color.white.opacity(0.08)
    public static let matrixDotActive = brandGreenLight
}

// MARK: - Metallic Screw View
public struct MetallicScrewView: View {
    public var size: CGFloat = 10

    public init(size: CGFloat = 10) {
        self.size = size
    }

    public var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(white: 0.35),
                            Color(white: 0.20),
                            Color(white: 0.30),
                            Color(white: 0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)

            Rectangle()
                .fill(Color(white: 0.15))
                .frame(width: size * 0.6, height: size * 0.15)
                .cornerRadius(0.5)

            Rectangle()
                .fill(Color(white: 0.15))
                .frame(width: size * 0.15, height: size * 0.6)
                .cornerRadius(0.5)
        }
    }
}

// MARK: - Color Hex Initializer
extension Color {
    public init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    public init(hex: String) {
        self.init(hexString: hex)
    }
}

public struct ReaderScene: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let assetName: String
    public let requiresPlus: Bool

    public static let all: [ReaderScene] = [
        ReaderScene(id: "lantern", title: "Lantern library", assetName: "SceneLantern", requiresPlus: false),
        ReaderScene(id: "train", title: "Night train", assetName: "SceneTrain", requiresPlus: true),
        ReaderScene(id: "meadow", title: "Paper bird", assetName: "SceneMeadow", requiresPlus: true)
    ]

    public static func scene(id: String) -> ReaderScene {
        all.first { $0.id == id } ?? all[0]
    }
}

@Observable
public final class ReaderSceneStore {
    public static let shared = ReaderSceneStore()
    public var selectedId: String {
        didSet { UserDefaults.standard.set(selectedId, forKey: "AudioBy.ReaderScene") }
    }

    public var active: ReaderScene {
        let scene = ReaderScene.scene(id: selectedId)
        if scene.requiresPlus && !EntitlementService.shared.isPlus {
            return ReaderScene.all[0]
        }
        return scene
    }

    private init() {
        selectedId = UserDefaults.standard.string(forKey: "AudioBy.ReaderScene") ?? "lantern"
    }

    public func choose(_ scene: ReaderScene) -> Bool {
        if scene.requiresPlus && !EntitlementService.shared.isPlus {
            return false
        }
        selectedId = scene.id
        return true
    }
}

public struct SceneBackdrop: View {
    public var scene: ReaderScene
    public var scrim: Double = 0.45

    public init(scene: ReaderScene, scrim: Double = 0.45) {
        self.scene = scene
        self.scrim = scrim
    }

    public var body: some View {
        ZStack {
            Image(scene.assetName)
                .resizable()
                .scaledToFill()
            Color.black.opacity(scrim)
        }
        .ignoresSafeArea()
    }
}

public struct ScenePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var showingPaywall: Bool
    @Bindable private var store = ReaderSceneStore.shared

    public init(showingPaywall: Binding<Bool>) {
        self._showingPaywall = showingPaywall
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    ForEach(ReaderScene.all) { scene in
                        Button {
                            if store.choose(scene) {
                                dismiss()
                            } else {
                                showingPaywall = true
                                dismiss()
                            }
                        } label: {
                            ZStack(alignment: .bottomLeading) {
                                Image(scene.assetName)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 140)
                                    .clipped()
                                HStack {
                                    Text(scene.title)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(.white)
                                    Spacer()
                                    if scene.requiresPlus && !EntitlementService.shared.isPlus {
                                        Text("Plus")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundStyle(.black)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Theme.brandGreen)
                                            .clipShape(Capsule())
                                    }
                                }
                                .padding(12)
                                .background(Color.black.opacity(0.35))
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(20)
            }
            .background(Theme.appBackground)
            .navigationTitle("Scenes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
