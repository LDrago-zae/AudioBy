import RevenueCat
import SwiftUI

private enum PaywallPlan: Hashable {
    case plus
    case premium
}

public struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var entitlements = EntitlementService.shared
    @State private var selectedPlan: PaywallPlan = .premium

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                Theme.appBackground.ignoresSafeArea()
                heroGlow
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 28) {
                            hero
                            planPicker
                            comparison
                            if let status = entitlements.refreshStatusMessage {
                                Text(status)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(entitlements.isPlus ? Theme.brandGreen : .orange)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 8)
                            } else if let error = entitlements.lastPurchaseError {
                                Text(error)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.orange)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 8)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                    }

                    footerCTA
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Theme.textDark)
                            .frame(width: 32, height: 32)
                            .background(Theme.surfaceWhite)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Theme.cardBorder, lineWidth: 1))
                    }
                    .accessibilityLabel("Close")
                }
            }
            .onAppear {
                if entitlements.isPremium {
                    selectedPlan = .premium
                } else if entitlements.isPlus {
                    selectedPlan = .plus
                }
            }
            .task {
                if entitlements.offering == nil {
                    await entitlements.loadOfferings()
                }
            }
        }
    }

    private var heroGlow: some View {
        RadialGradient(
            colors: [Theme.brandGreen.opacity(0.22), Theme.brandCyan.opacity(0.06), Color.clear],
            center: .top,
            startRadius: 20,
            endRadius: 420
        )
    }

    private var hero: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Theme.brandGreen.opacity(0.15))
                    .frame(width: 108, height: 108)
                Circle()
                    .stroke(Theme.brandGreen.opacity(0.35), lineWidth: 1)
                    .frame(width: 88, height: 88)
                Image(systemName: "headphones")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.brandGreenLight, Theme.brandCyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: 8) {
                Text("Listen without limits")
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundColor(Theme.textDark)
                    .multilineTextAlignment(.center)

                Text("The public catalog stays free. Upgrade when you want unlimited libraries, offline listening, and studio-quality narration.")
                    .font(.system(size: 15))
                    .foregroundColor(Theme.textMuted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }
        }
        .padding(.top, 12)
    }

    private var planPicker: some View {
        VStack(spacing: 12) {
            planCard(
                plan: .premium,
                title: "Premium",
                price: localizedPrice(for: entitlements.premiumPackage, fallback: "$9.99"),
                cadence: "per month",
                badge: "Most popular",
                points: [
                    "Everything in Plus",
                    "ElevenLabs studio voices",
                    "Cached neural narration"
                ]
            )

            planCard(
                plan: .plus,
                title: "Plus",
                price: localizedPrice(for: entitlements.plusPackage, fallback: "$4.99"),
                cadence: "per month",
                badge: nil,
                points: [
                    "Unlimited PDF imports",
                    "Unlimited offline downloads",
                    "On-device voices included"
                ]
            )
        }
    }

    /// Prefers the price configured in App Store Connect (via RevenueCat) in the user's local
    /// storefront currency. Falls back to a display-only placeholder while offerings are loading
    /// or haven't been configured yet (e.g. during local development).
    private func localizedPrice(for package: Package?, fallback: String) -> String {
        package?.storeProduct.localizedPriceString ?? fallback
    }

    private func planCard(
        plan: PaywallPlan,
        title: String,
        price: String,
        cadence: String,
        badge: String?,
        points: [String]
    ) -> some View {
        let selected = selectedPlan == plan
        return Button {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                selectedPlan = plan
            }
        } label: {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(title)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(Theme.textDark)
                            if let badge {
                                Text(badge)
                                    .font(.system(size: 10, weight: .heavy))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Theme.brandGreen)
                                    .clipShape(Capsule())
                            }
                        }
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(price)
                                .font(.system(size: 22, weight: .heavy, design: .rounded))
                                .foregroundColor(Theme.textDark)
                            Text(cadence)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Theme.textMuted)
                        }
                    }
                    Spacer()
                    Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24))
                        .foregroundColor(selected ? Theme.brandGreen : Theme.textMuted.opacity(0.45))
                }

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(points, id: \.self) { point in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Theme.brandGreen)
                                .frame(width: 16)
                            Text(point)
                                .font(.system(size: 14))
                                .foregroundColor(Theme.textMuted)
                        }
                    }
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surfaceWhite)
            .cornerRadius(22)
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(selected ? Theme.brandGreen : Theme.cardBorder, lineWidth: selected ? 2 : 1)
            )
            .shadow(color: selected ? Theme.brandGreen.opacity(0.18) : .clear, radius: 16, y: 6)
        }
        .buttonStyle(.plain)
        .disabled(isCurrent(plan))
        .opacity(isCurrent(plan) && selectedPlan != plan ? 0.7 : 1)
    }

    private var comparison: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What you get")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Theme.textMuted)
                .textCase(.uppercase)
                .tracking(0.8)

            VStack(spacing: 0) {
                HStack {
                    Text("Feature")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Theme.textMuted)
                    Spacer()
                    Text("Free").font(.system(size: 11, weight: .bold)).foregroundColor(Theme.textMuted).frame(width: 52)
                    Text("Plus").font(.system(size: 11, weight: .bold)).foregroundColor(Theme.textMuted).frame(width: 52)
                    Text("Pro").font(.system(size: 11, weight: .bold)).foregroundColor(Theme.textMuted).frame(width: 52)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)

                comparisonRow("Public catalog", free: true, plus: true, premium: true)
                comparisonRow("On-device TTS", free: true, plus: true, premium: true)
                comparisonRow("PDF imports", free: false, plus: true, premium: true, freeNote: "1 book")
                comparisonRow("Offline downloads", free: false, plus: true, premium: true, freeNote: "1 book")
                comparisonRow("Studio voices", free: false, plus: false, premium: true)
            }
            .background(Theme.surfaceWhite)
            .cornerRadius(18)
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.cardBorder, lineWidth: 1))
        }
    }

    private func comparisonRow(
        _ title: String,
        free: Bool,
        plus: Bool,
        premium: Bool,
        freeNote: String? = nil
    ) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Theme.textDark)
            Spacer()
            comparisonMark(free, note: freeNote)
                .frame(width: 52)
            comparisonMark(plus)
                .frame(width: 52)
            comparisonMark(premium)
                .frame(width: 52)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Theme.cardBorder)
                .frame(height: 1)
        }
    }

    private func comparisonMark(_ included: Bool, note: String? = nil) -> some View {
        Group {
            if let note, !included {
                Text(note)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Theme.textMuted)
            } else if included {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Theme.brandGreen)
            } else {
                Image(systemName: "minus")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Theme.textMuted.opacity(0.4))
            }
        }
    }

    private var footerCTA: some View {
        VStack(spacing: 12) {
            if isCurrent(selectedPlan) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Theme.brandGreen)
                    Text(selectedPlan == .premium ? "You’re on Premium" : "You’re on Plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Theme.textDark)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Theme.surfaceWhite)
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.brandGreen, lineWidth: 1.5))
            } else {
                Button {
                    openWebUpgrade()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "safari")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Upgrade on Web (\(planTitle))")
                            .font(.system(size: 16, weight: .bold))
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        LinearGradient(
                            colors: [Theme.brandGreenLight, Theme.brandGreen],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: Theme.brandGreen.opacity(0.3), radius: 8, y: 3)
                }

                Button {
                    Task { await entitlements.refreshEntitlements() }
                } label: {
                    HStack(spacing: 6) {
                        if entitlements.isRefreshing {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        Text("Already subscribed? Refresh status")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(Theme.brandGreen)
                    .padding(.vertical, 4)
                }
                .disabled(entitlements.isRefreshing)
            }

            Text("AudioBy subscriptions are multiplatform and managed via our secure web checkout. Sign in with your AudioBy account on any device to unlock your subscription.")
                .font(.system(size: 11))
                .foregroundColor(Theme.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .background(.ultraThinMaterial)
    }

    private var planTitle: String {
        selectedPlan == .premium ? "Premium" : "Plus"
    }

    private func isCurrent(_ plan: PaywallPlan) -> Bool {
        switch plan {
        case .plus: return entitlements.isPlus && !entitlements.isPremium
        case .premium: return entitlements.isPremium
        }
    }

    private func openWebUpgrade() {
        if let url = URL(string: "https://audioby.app#pricing") {
            UIApplication.shared.open(url)
        }
    }
}
