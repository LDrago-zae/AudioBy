/**
 * RevenueCat Server-Side REST API Helper
 *
 * Used by webhooks (Lemon Squeezy, Stripe, etc.) to grant and revoke
 * Plus / Premium entitlements for users using their Firebase UID.
 */

const REVENUECAT_API_BASE = "https://api.revenuecat.com/v1";

function getSecretKey(): string {
  const key = process.env.REVENUECAT_SECRET_KEY || process.env.REVENUECAT_API_KEY;
  if (!key) {
    throw new Error(
      "REVENUECAT_SECRET_KEY is not defined in environment variables. Set this in .env.local."
    );
  }
  return key;
}

export interface RevenueCatSubscriberResponse {
  request_date: string;
  request_date_ms: number;
  subscriber: {
    entitlements: Record<
      string,
      {
        expires_date: string | null;
        grace_period_expires_date: string | null;
        product_identifier: string;
        purchase_date: string;
      }
    >;
    first_seen: string;
    original_app_user_id: string;
    subscriptions: Record<string, unknown>;
  };
}

/**
 * Fetch a subscriber's current entitlements and status from RevenueCat
 */
export async function getRevenueCatSubscriber(
  appUserId: string
): Promise<RevenueCatSubscriberResponse> {
  const secretKey = getSecretKey();
  const res = await fetch(`${REVENUECAT_API_BASE}/subscribers/${encodeURIComponent(appUserId)}`, {
    method: "GET",
    headers: {
      Authorization: `Bearer ${secretKey}`,
      Accept: "application/json",
      "Content-Type": "application/json",
    },
  });

  if (!res.ok) {
    const errorText = await res.text();
    throw new Error(`RevenueCat fetch error (${res.status}): ${errorText}`);
  }

  return res.json();
}

/**
 * Grant a promotional entitlement to a subscriber (Plus or Premium).
 * This instantly unlocks the entitlement on both Web and the iOS App.
 */
export async function grantRevenueCatEntitlement(
  appUserId: string,
  entitlementId: "plus" | "premium",
  duration: "monthly" | "yearly" | "lifetime" = "monthly"
): Promise<{ success: boolean; data: unknown }> {
  const secretKey = getSecretKey();
  const endpoint = `${REVENUECAT_API_BASE}/subscribers/${encodeURIComponent(
    appUserId
  )}/entitlements/${encodeURIComponent(entitlementId)}/promotional`;

  const res = await fetch(endpoint, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${secretKey}`,
      Accept: "application/json",
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      duration,
    }),
  });

  if (!res.ok) {
    const errorText = await res.text();
    throw new Error(
      `RevenueCat grant error (${res.status}) for ${appUserId} on ${entitlementId}: ${errorText}`
    );
  }

  const data = await res.json();
  return { success: true, data };
}

/**
 * Revoke promotional entitlements when a subscription expires or is cancelled.
 */
export async function revokeRevenueCatEntitlement(
  appUserId: string,
  entitlementId: "plus" | "premium"
): Promise<{ success: boolean }> {
  const secretKey = getSecretKey();
  const endpoint = `${REVENUECAT_API_BASE}/subscribers/${encodeURIComponent(
    appUserId
  )}/entitlements/${encodeURIComponent(entitlementId)}/revoke_promotionals`;

  const res = await fetch(endpoint, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${secretKey}`,
      Accept: "application/json",
      "Content-Type": "application/json",
    },
  });

  if (!res.ok) {
    const errorText = await res.text();
    throw new Error(
      `RevenueCat revoke error (${res.status}) for ${appUserId} on ${entitlementId}: ${errorText}`
    );
  }

  return { success: true };
}
