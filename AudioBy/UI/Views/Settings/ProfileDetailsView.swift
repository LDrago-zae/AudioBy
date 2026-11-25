import SwiftUI

public struct ProfileDetailsView: View {
    @AppStorage("isDarkMode") private var isDarkMode: Bool = true
    @AppStorage("autoRewindOnResume") private var autoRewindOnResume: Bool = true
    @AppStorage("highQualityAudio") private var highQualityAudio: Bool = true
    @AppStorage("downloadWifiOnly") private var downloadWifiOnly: Bool = true
    @State private var cacheLimitChoice: Int = 2_000_000_000
    @Bindable var repository = AudiobookRepository.shared
    @Bindable var playerService = AudioPlayerService.shared
    @Bindable var downloadManager = DownloadManager.shared
    @Bindable var entitlements = EntitlementService.shared
    @State private var showingClearStorageAlert = false
    @State private var showingPaywall = false

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                MangaTheme.surface.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        HStack(spacing: 12) {
                            Button {
                                AppNavigationState.shared.openSidebar()
                            } label: {
                                Image(systemName: "line.3.horizontal")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(MangaTheme.ink)
                                    .frame(width: 44, height: 44)
                                    .background(MangaTheme.surfaceLow)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(MangaTheme.hairline, lineWidth: 1))
                            }
                            .accessibilityLabel("Open Menu")

                            VStack(alignment: .leading, spacing: 1) {
                                Text("設定 / PREFERENCES")
                                    .font(.system(size: 10, weight: .bold))
                                    .tracking(1.2)
                                    .foregroundStyle(MangaTheme.vermilion)
                                Text("Settings")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundStyle(MangaTheme.ink)
                            }

                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                        HStack(spacing: 16) {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .foregroundColor(Theme.stone)
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 4) {
                                Text(AuthService.shared.displayName)
                                    .font(.system(size: 19, weight: .bold))
                                    .foregroundColor(Theme.textDark)

                                if !AuthService.shared.email.isEmpty {
                                    Text(AuthService.shared.email)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(Theme.textMuted)
                                }

                                Text(membershipLabel)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Theme.textMuted)

                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(Theme.brandGreen)
                                        .frame(width: 8, height: 8)
                                    Text(entitlements.tier == .free ? "Free" : entitlements.tier.rawValue.capitalized)
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(Theme.ember)
                                }
                                .padding(.top, 2)
                            }
                        }
                        .padding(18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.surfaceWhite)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Theme.cardBorder, lineWidth: 1)
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                        Button(role: .destructive) {
                            AuthService.shared.signOut()
                        } label: {
                            HStack {
                                Text("Sign out")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.red)
                                Spacer()
                            }
                            .padding(16)
                            .background(Theme.surfaceWhite)
                            .cornerRadius(18)
                            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.cardBorder, lineWidth: 1))
                        }
                        .padding(.horizontal, 20)

                        Button {
                            showingPaywall = true
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("AudioBy Plus & Premium")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(Theme.textDark)
                                    Text("Unlimited PDFs, offline downloads, studio voices")
                                        .font(.system(size: 12))
                                        .foregroundColor(Theme.textMuted)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(Theme.textMuted)
                            }
                            .padding(16)
                            .background(Theme.surfaceWhite)
                            .cornerRadius(18)
                            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.cardBorder, lineWidth: 1))
                        }
                        .padding(.horizontal, 20)

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Debug entitlements")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(Theme.textDark)
                            HStack(spacing: 8) {
                                ForEach([SubscriptionTier.free, .plus, .premium], id: \.self) { tier in
                                    Button(tier.rawValue.capitalized) {
                                        entitlements.setDebugTier(tier)
                                    }
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(entitlements.tier == tier ? Theme.onAccent : Theme.textDark)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(entitlements.tier == tier ? Theme.ember : Theme.surfaceWhite)
                                    .clipShape(Capsule())
                                    .overlay(Capsule().stroke(Theme.cardBorder, lineWidth: 1))
                                }
                            }
                        }
                        .padding(.horizontal, 20)

                        // Appearance & Theme Switcher (Clean Single Toggle Row)
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Appearance & Theme")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(Theme.textDark)
                                .padding(.horizontal, 20)

                            HStack {
                                HStack(spacing: 12) {
                                    Image(systemName: isDarkMode ? "moon.stars.fill" : "sun.max.fill")
                                        .font(.system(size: 18))
                                        .foregroundStyle(MangaTheme.vermilion)
                                        .frame(width: 38, height: 38)
                                        .background(MangaTheme.vermilionFixed)
                                        .clipShape(Circle())

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(isDarkMode ? "Dark Theme" : "Light Paper Theme")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundStyle(MangaTheme.ink)
                                        Text(isDarkMode ? "Sumi-e ink canvas, cinnabar accents" : "Warm washi paper, charcoal marks")
                                            .font(.system(size: 12))
                                            .foregroundStyle(MangaTheme.secondary)
                                    }
                                }

                                Spacer()

                                Toggle("", isOn: $isDarkMode.animation(.easeInOut(duration: 0.25)))
                                    .tint(MangaTheme.vermilion)
                                    .labelsHidden()
                            }
                            .padding(16)
                            .background(MangaTheme.surfaceLow)
                            .clipShape(RoundedRectangle(cornerRadius: MangaTheme.cardRadius, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: MangaTheme.cardRadius, style: .continuous)
                                    .stroke(MangaTheme.hairline, lineWidth: 1)
                            )
                            .padding(.horizontal, 20)
                        }

                        // Audio Playback Preferences
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Audio & Playback Settings")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(Theme.textDark)
                                .padding(.horizontal, 20)

                            VStack(spacing: 1) {
                                ToggleRow(
                                    title: "Auto-Rewind on Resume",
                                    subtitle: "Rewinds 10s after long pause to restore context",
                                    isOn: $autoRewindOnResume
                                )

                                Divider().background(Theme.cardBorder).padding(.horizontal, 16)

                                ToggleRow(
                                    title: "Voice Clarity Boost",
                                    subtitle: "Enhance narrator vocal clarity and cut background hiss",
                                    isOn: $playerService.isVocalClarityBoosted
                                )

                                Divider().background(Theme.cardBorder).padding(.horizontal, 16)

                                ToggleRow(
                                    title: "High Quality Audio",
                                    subtitle: "192 kbps high bitrate stream when available",
                                    isOn: $highQualityAudio
                                )
                            }
                            .background(Theme.surfaceWhite)
                            .cornerRadius(18)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(Theme.cardBorder, lineWidth: 1)
                            )
                            .padding(.horizontal, 20)
                        }

                        // Offline Downloads & Storage
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Storage & Downloads")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(Theme.textDark)
                                .padding(.horizontal, 20)

                            VStack(spacing: 1) {
                                ToggleRow(
                                    title: "Download Over Wi-Fi Only",
                                    subtitle: "Avoid cellular data consumption for audiobooks",
                                    isOn: $downloadWifiOnly
                                )

                                Divider().background(Theme.cardBorder).padding(.horizontal, 16)

                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Downloaded content limit")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(Theme.textDark)
                                    Text("Oldest cached books are removed first when the limit is reached.")
                                        .font(.system(size: 12))
                                        .foregroundColor(Theme.textMuted)
                                    Picker("Limit", selection: $cacheLimitChoice) {
                                        Text("500 MB").tag(500_000_000)
                                        Text("1 GB").tag(1_000_000_000)
                                        Text("2 GB").tag(2_000_000_000)
                                        Text("5 GB").tag(5_000_000_000)
                                        Text("Unlimited").tag(0)
                                    }
                                    .pickerStyle(.menu)
                                    .tint(Theme.brandGreen)
                                }
                                .padding(16)
                                .onChange(of: cacheLimitChoice) { _, value in
                                    UserDefaults.standard.set(Int64(value), forKey: ContentCache.limitDefaultsKey)
                                    Task { await ContentCache.shared.evictIfNeeded() }
                                    downloadManager.scanDownloadedFiles()
                                }

                                Divider().background(Theme.cardBorder).padding(.horizontal, 16)

                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Offline Storage Used")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(Theme.textDark)
                                        Text("\(downloadManager.formattedStorageUsed) occupied")
                                            .font(.system(size: 12))
                                            .foregroundColor(Theme.textMuted)
                                    }

                                    Spacer()

                                    Button {
                                        showingClearStorageAlert = true
                                    } label: {
                                        Text("Clear Cache")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(.red)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.red.opacity(0.15))
                                            .clipShape(Capsule())
                                    }
                                }
                                .padding(16)
                            }
                            .background(Theme.surfaceWhite)
                            .cornerRadius(18)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(Theme.cardBorder, lineWidth: 1)
                            )
                            .padding(.horizontal, 20)
                        }

                        // Bookmarks Count Card
                        NavigationLink(destination: BookmarksView()) {
                            HStack {
                                Image(systemName: "bookmark.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(Theme.brandGreen)
                                    .frame(width: 36, height: 36)
                                    .background(Theme.brandGreen.opacity(0.15))
                                    .clipShape(Circle())

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Saved Bookmarks & Quotes")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(Theme.textDark)
                                    Text("\(playerService.bookmarks.count) saved timestamps")
                                        .font(.system(size: 12))
                                        .foregroundColor(Theme.textMuted)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Theme.textMuted)
                            }
                            .padding(16)
                            .background(Theme.surfaceWhite)
                            .cornerRadius(18)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(Theme.cardBorder, lineWidth: 1)
                            )
                            .padding(.horizontal, 20)
                        }

                        Spacer(minLength: 160)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                cacheLimitChoice = Int(ContentCache.currentLimitBytes())
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .confirmationDialog("Clear Offline Audio Cache?", isPresented: $showingClearStorageAlert, titleVisibility: .visible) {
                Button("Delete All Downloads", role: .destructive) {
                    downloadManager.clearAllCache()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will remove downloaded audiobooks and cached book text from your device.")
            }
        }
    }

    private var membershipLabel: String {
        switch entitlements.tier {
        case .free: return "Free • 1 PDF import • 1 offline title"
        case .plus: return "Plus • Unlimited PDFs & downloads"
        case .premium: return "Premium • Studio voices enabled"
        }
    }
}

private struct ToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Theme.textDark)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textMuted)
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .tint(Theme.brandGreen)
                .labelsHidden()
        }
        .padding(16)
    }
}
