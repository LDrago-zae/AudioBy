import Foundation
import Observation
import StoreKit

public enum SubscriptionTier: String, Codable, Sendable {
    case free
    case plus
    case premium
}

@Observable
public final class EntitlementService: @unchecked Sendable {
    public static let shared = EntitlementService()

    public var tier: SubscriptionTier = .free
    public var isPurchasing: Bool = false
    public var lastPurchaseError: String?

    private let debugUnlockKey = "AudioBy.DebugUnlockTier"
    private let productPlusMonthly = "com.audioby.plus.monthly"
    private let productPremiumMonthly = "com.audioby.premium.monthly"

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

    public init() {
        restoreDebugUnlock()
        Task { await refreshEntitlements() }
    }

    public func refreshEntitlements() async {
        if UserDefaults.standard.string(forKey: debugUnlockKey) != nil {
            restoreDebugUnlock()
            return
        }
        var highest: SubscriptionTier = .free
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if transaction.productID.contains("premium") {
                highest = .premium
            } else if transaction.productID.contains("plus"), highest != .premium {
                highest = .plus
            }
        }
        await MainActor.run {
            self.tier = highest
        }
    }

    public func purchasePlus() async {
        await purchase(productID: productPlusMonthly, fallbackTier: .plus)
    }

    public func purchasePremium() async {
        await purchase(productID: productPremiumMonthly, fallbackTier: .premium)
    }

    public func restorePurchases() async {
        do {
            try await AppStore.sync()
            await refreshEntitlements()
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

    private func purchase(productID: String, fallbackTier: SubscriptionTier) async {
        await MainActor.run {
            self.isPurchasing = true
            self.lastPurchaseError = nil
        }
        do {
            let products = try await Product.products(for: [productID])
            guard let product = products.first else {
                await MainActor.run {
                    self.isPurchasing = false
                    self.lastPurchaseError = "Products are not configured in App Store Connect yet. Use Debug unlock in Settings."
                }
                return
            }
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified = verification {
                    await refreshEntitlements()
                }
            case .userCancelled, .pending:
                break
            @unknown default:
                break
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
