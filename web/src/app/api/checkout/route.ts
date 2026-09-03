import { NextResponse } from "next/server";
import { grantRevenueCatEntitlement } from "@/lib/revenuecat-admin";

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { plan, userId, email, testActivate } = body;

    if (plan !== "plus" && plan !== "premium") {
      return NextResponse.json({ error: "Invalid plan specified." }, { status: 400 });
    }

    // 1. Check for Lemon Squeezy checkout URLs (Recommended for direct UBL payouts)
    const lsPlusUrl = process.env.NEXT_PUBLIC_LEMONSQUEEZY_PLUS_URL;
    const lsPremiumUrl = process.env.NEXT_PUBLIC_LEMONSQUEEZY_PREMIUM_URL;
    const lsTargetUrl = plan === "premium" ? lsPremiumUrl : lsPlusUrl;

    if (lsTargetUrl) {
      const url = new URL(lsTargetUrl);
      if (userId) {
        url.searchParams.set("checkout[custom][user_id]", userId);
        url.searchParams.set("checkout[custom][plan]", plan);
      }
      if (email) {
        url.searchParams.set("checkout[email]", email);
      }
      return NextResponse.json({ url: url.toString(), provider: "lemonsqueezy" });
    }

    // 2. Check for Stripe checkout links (if configured)
    const stripePlusUrl = process.env.NEXT_PUBLIC_STRIPE_PLUS_URL;
    const stripePremiumUrl = process.env.NEXT_PUBLIC_STRIPE_PREMIUM_URL;
    const stripeTargetUrl = plan === "premium" ? stripePremiumUrl : stripePlusUrl;

    if (stripeTargetUrl) {
      const url = new URL(stripeTargetUrl);
      if (userId) {
        url.searchParams.set("client_reference_id", userId);
      }
      if (email) {
        url.searchParams.set("prefilled_email", email);
      }
      return NextResponse.json({ url: url.toString(), provider: "stripe" });
    }

    // 3. Direct Test Activation (if testActivate is requested and Secret Key is configured)
    const hasSecretKey = Boolean(
      process.env.REVENUECAT_SECRET_KEY || process.env.REVENUECAT_API_KEY
    );

    if (testActivate && hasSecretKey && userId) {
      try {
        await grantRevenueCatEntitlement(userId, plan, "monthly");
        return NextResponse.json({
          success: true,
          mode: "activated",
          plan,
          userId,
          message: `Successfully granted ${plan} entitlement in RevenueCat for user ${userId}.`,
        });
      } catch (err: unknown) {
        const msg = err instanceof Error ? err.message : "RevenueCat activation error";
        return NextResponse.json({ error: msg }, { status: 500 });
      }
    }

    // 4. Default Demo / Mock Response
    return NextResponse.json({
      mode: "demo",
      plan,
      userId: userId || "anonymous",
      email: email || "listener@audioby.app",
      message:
        "Ready for web subscription checkout. Configure NEXT_PUBLIC_LEMONSQUEEZY_PLUS_URL and NEXT_PUBLIC_LEMONSQUEEZY_PREMIUM_URL in .env.local to route payouts to Payoneer/UBL.",
    });
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : "Internal Server Error";
    return NextResponse.json({ error: message }, { status: 500 });
  }
}
