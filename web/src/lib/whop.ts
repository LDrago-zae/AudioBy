import { createHmac, timingSafeEqual } from "crypto";

const WHOP_API_BASE = "https://api.whop.com/api/v1";

export type CheckoutPlan = "plus" | "premium";

function apiKey(): string {
  const key = process.env.WHOP_API_KEY;
  if (!key) {
    throw new Error("WHOP_API_KEY is not set.");
  }
  return key;
}

export function planIdFor(plan: CheckoutPlan): string | undefined {
  return plan === "premium" ? process.env.WHOP_PREMIUM_PLAN_ID : process.env.WHOP_PLUS_PLAN_ID;
}

export function whopPlansConfigured(): boolean {
  return Boolean(process.env.WHOP_API_KEY && process.env.WHOP_PLUS_PLAN_ID && process.env.WHOP_PREMIUM_PLAN_ID);
}

export function planFromWhopPlanId(planId: string | undefined): CheckoutPlan | null {
  if (!planId) return null;
  if (planId === process.env.WHOP_PREMIUM_PLAN_ID) return "premium";
  if (planId === process.env.WHOP_PLUS_PLAN_ID) return "plus";
  return null;
}

interface CheckoutConfiguration {
  purchase_url?: string;
  id?: string;
}

export async function createWhopCheckout(input: {
  plan: CheckoutPlan;
  userId?: string;
  email?: string;
}): Promise<string> {
  const planId = planIdFor(input.plan);
  if (!planId) {
    throw new Error(`Missing Whop plan id for ${input.plan}.`);
  }

  const res = await fetch(`${WHOP_API_BASE}/checkout_configurations`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey()}`,
      "Content-Type": "application/json",
      Accept: "application/json",
    },
    body: JSON.stringify({
      plan_id: planId,
      redirect_url: "https://audioby.vercel.app/#pricing",
      metadata: {
        user_id: input.userId ?? "",
        customer_id: input.userId ?? "",
        plan: input.plan,
        ...(input.email ? { email: input.email } : {}),
      },
    }),
  });

  if (!res.ok) {
    const detail = await res.text();
    throw new Error(`Whop checkout failed (${res.status}): ${detail}`);
  }

  const data = (await res.json()) as CheckoutConfiguration;
  if (!data.purchase_url) {
    throw new Error("Whop checkout response did not include purchase_url.");
  }
  return data.purchase_url;
}

/** Whop signs with the raw `ws_` secret. Do not strip the prefix or base64-decode it. */

/**
 * Standard Webhooks signature used by Whop.
 * https://docs.whop.com/developer/guides/webhooks
 */
export function verifyWhopWebhook(rawBody: string, headers: Headers): void {
  const secret = process.env.WHOP_WEBHOOK_SECRET;
  if (!secret) {
    throw new Error("WHOP_WEBHOOK_SECRET is not set.");
  }

  const id = headers.get("webhook-id");
  const timestamp = headers.get("webhook-timestamp");
  const signatureHeader = headers.get("webhook-signature");
  if (!id || !timestamp || !signatureHeader) {
    throw new Error("Missing Whop webhook signature headers.");
  }

  const ts = Number(timestamp);
  const now = Math.floor(Date.now() / 1000);
  if (!Number.isFinite(ts) || Math.abs(now - ts) > 5 * 60) {
    throw new Error("Whop webhook timestamp is outside the allowed window.");
  }

  const expected = createHmac("sha256", secret)
    .update(`${id}.${timestamp}.${rawBody}`)
    .digest("base64");

  const candidates = signatureHeader
    .split(" ")
    .map((part) => part.split(",")[1])
    .filter((value): value is string => Boolean(value));

  const expectedBuf = Buffer.from(expected);
  const valid = candidates.some((candidate) => {
    const given = Buffer.from(candidate);
    return given.length === expectedBuf.length && timingSafeEqual(given, expectedBuf);
  });

  if (!valid) {
    throw new Error("Invalid Whop webhook signature.");
  }
}
