import { NextResponse } from "next/server";
import crypto from "crypto";
import {
  grantRevenueCatEntitlement,
  revokeRevenueCatEntitlement,
} from "@/lib/revenuecat-admin";

export async function POST(request: Request) {
  try {
    const rawBody = await request.text();
    const signature = request.headers.get("x-signature");
    const webhookSecret = process.env.LEMONSQUEEZY_WEBHOOK_SECRET;

    // Verify webhook signature if secret is configured
    if (webhookSecret && signature) {
      const hmac = crypto.createHmac("sha256", webhookSecret);
      const digest = Buffer.from(hmac.update(rawBody).digest("hex"), "utf8");
      const signatureBuffer = Buffer.from(signature, "utf8");

      if (
        signatureBuffer.length !== digest.length ||
        !crypto.timingSafeEqual(digest, signatureBuffer)
      ) {
        return NextResponse.json({ error: "Invalid signature." }, { status: 401 });
      }
    }

    const payload = JSON.parse(rawBody);
    const eventName: string = payload?.meta?.event_name || "";
    const customData = payload?.meta?.custom_data || {};
    const userId: string = customData.user_id || customData.userId || "";

    // Determine target plan
    let plan: "plus" | "premium" = "plus";
    const explicitPlan = (customData.plan || "").toLowerCase();
    const productName = (payload?.data?.attributes?.product_name || "").toLowerCase();
    const variantName = (payload?.data?.attributes?.variant_name || "").toLowerCase();

    if (
      explicitPlan === "premium" ||
      productName.includes("premium") ||
      variantName.includes("premium")
    ) {
      plan = "premium";
    }

    if (!userId) {
      // In case user_id wasn't in custom_data (e.g. test ping)
      return NextResponse.json({
        received: true,
        warning: "No user_id found in custom_data. Entitlement skipped.",
        event: eventName,
      });
    }

    // Process subscription events
    switch (eventName) {
      case "subscription_created":
      case "subscription_resumed":
      case "subscription_updated":
      case "order_created": {
        const status = payload?.data?.attributes?.status;
        // Only grant if status is active, on_trial, or completed order
        if (
          !status ||
          status === "active" ||
          status === "on_trial" ||
          status === "paid" ||
          eventName === "order_created"
        ) {
          await grantRevenueCatEntitlement(userId, plan, "monthly");
        }
        break;
      }

      case "subscription_cancelled":
      case "subscription_expired": {
        await revokeRevenueCatEntitlement(userId, plan);
        break;
      }

      default:
        // Unhandled event, log and acknowledge
        break;
    }

    return NextResponse.json({
      received: true,
      event: eventName,
      userId,
      plan,
    });
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : "Webhook processing error";
    console.error("Lemon Squeezy Webhook Error:", message);
    return NextResponse.json({ error: message }, { status: 500 });
  }
}
