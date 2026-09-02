import Foundation
import Observation
import RevenueCat

public enum SubscriptionTier: String, Codable, Sendable {
    case free
    case plus
    case premium
}

@Observable
public final class EntitlementService: NSObject, @unchecked Sendable {
    public static let shared = EntitlementService()

    public var tier: SubscriptionTier = .free
    public var isPurchasing: Bool = false
    public var lastPurchaseError: String?
    public var offering: Offering?

    private let debugUnlockKey = "AudioBy.DebugUnlockTier"

    /// Product identifiers as configured in App Store Connect / RevenueCat.
    private let productPlusMonthly = "com.audioby.plus.monthly"
    private let productPremiumMonthly = "com.audioby.premium.monthly"

    /// RevenueCat entitlement identifiers as configured in the RevenueCat dashboard.
    private let entitlementPlus = "plus"
    private let entitlementPremium = "premium"

    public var isPlus: Bool { tier == .plus || tier == .premium }
    public var isPremium: Bool { tier == .premium }

    public var importedPDFCount: Int {
        UserImportService.shared.loadImportedBooks().count
    }

    public var canImportPDF: Bool {
        isPlus || importedPDFCount < 1
    }

    public var canDownloadMore: Bool {
        if isPlus { return true }
        return DownloadManager.shared.downloadedBookIds.count < 1
    }

    public var remainingFreeDownloads: Int {
        max(0, 1 - DownloadManager.shared.downloadedBookIds.count)
    }

    /// RevenueCat package backing the Plus plan in the current offering, if fetched.
    public var plusPackage: Package? {
        package(forProductID: productPlusMonthly)
    }

    /// RevenueCat package backing the Premium plan in the current offering, if fetched.
    public var premiumPackage: Package? {
        package(forProductID: productPremiumMonthly)
    }

    public override init() {
        super.init()
        restoreDebugUnlock()
        if Purchases.isConfigured {
            Purchases.shared.delegate = self
        }
        Task {
            await loadOfferings()
            await refreshEntitlements()
        }
    }

    public func loadOfferings() async {
        guard Purchases.isConfigured else { return }
        do {
            let offerings = try await Purchases.shared.offerings()
            await MainActor.run {
                self.offering = offerings.current
            }
        } catch {
            await MainActor.run {
                self.lastPurchaseError = error.localizedDescription
            }
        }
    }

    public func refreshEntitlements() async {
        if UserDefaults.standard.string(forKey: debugUnlockKey) != nil {
            restoreDebugUnlock()
            return
        }
        guard Purchases.isConfigured else { return }
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            await MainActor.run {
                self.apply(customerInfo)
            }
        } catch {
            await MainActor.run {
                self.lastPurchaseError = error.localizedDescription
            }
        }
    }

    public func purchasePlus() async {
        await purchase(package: plusPackage, fallbackProductID: productPlusMonthly)
    }

    public func purchasePremium() async {
        await purchase(package: premiumPackage, fallbackProductID: productPremiumMonthly)
    }

    public func restorePurchases() async {
        guard Purchases.isConfigured else {
            await MainActor.run {
                self.lastPurchaseError = "Purchases are not configured yet. Set REVENUECAT_API_KEY in Secrets.xcconfig."
            }
            return
        }
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            await MainActor.run {
                self.apply(customerInfo)
            }
        } catch {
            await MainActor.run {
                self.lastPurchaseError = error.localizedDescription
            }
        }
    }

    public func setDebugTier(_ tier: SubscriptionTier) {
        UserDefaults.standard.set(tier.rawValue, forKey: debugUnlockKey)
        self.tier = tier
    }

    private func restoreDebugUnlock() {
        if let raw = UserDefaults.standard.string(forKey: debugUnlockKey),
           let stored = SubscriptionTier(rawValue: raw) {
            tier = stored
        }
    }

    private func package(forProductID productID: String) -> Package? {
        offering?.availablePackages.first { $0.storeProduct.productIdentifier == productID }
    }

    private func apply(_ customerInfo: CustomerInfo) {
        if customerInfo.entitlements[entitlementPremium]?.isActive == true {
            tier = .premium
        } else if customerInfo.entitlements[entitlementPlus]?.isActive == true {
            tier = .plus
        } else {
            tier = .free
        }
    }

    private func purchase(package: Package?, fallbackProductID: String) async {
        await MainActor.run {
            self.isPurchasing = true
            self.lastPurchaseError = nil
        }
        guard Purchases.isConfigured else {
            await MainActor.run {
                self.isPurchasing = false
                self.lastPurchaseError = "Purchases are not configured yet. Set REVENUECAT_API_KEY in Secrets.xcconfig, or use Debug unlock in Settings."
            }
            return
        }
        guard let package else {
            await MainActor.run {
                self.isPurchasing = false
                self.lastPurchaseError = "\(fallbackProductID) is not available in the current RevenueCat offering yet. Use Debug unlock in Settings while you finish App Store Connect / RevenueCat setup."
            }
            return
        }
        do {
            let result = try await Purchases.shared.purchase(package: package)
            if !result.userCancelled {
                await MainActor.run {
                    self.apply(result.customerInfo)
                }
            }
        } catch {
            await MainActor.run {
                self.lastPurchaseError = error.localizedDescription
            }
        }
        await MainActor.run {
            self.isPurchasing = false
        }
    }
}

// MARK: - PurchasesDelegate

extension EntitlementService: PurchasesDelegate {
    public func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            self.apply(customerInfo)
        }
    }
}
