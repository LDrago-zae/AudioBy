import { NextResponse } from "next/server";
import { grantRevenueCatEntitlement } from "@/lib/revenuecat-admin";
import { createWhopCheckout, whopPlansConfigured } from "@/lib/whop";

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { plan, userId, email, testActivate } = body;

    if (plan !== "plus" && plan !== "premium") {
      return NextResponse.json({ error: "Invalid plan specified." }, { status: 400 });
    }

    if (whopPlansConfigured()) {
      const url = await createWhopCheckout({
        plan,
        userId: typeof userId === "string" ? userId : undefined,
        email: typeof email === "string" ? email : undefined,
      });
      return NextResponse.json({ url, provider: "whop" });
    }

    const hasSecretKey = Boolean(
      process.env.REVENUECAT_SECRET_KEY || process.env.REVENUECAT_API_KEY
    );

    if (testActivate && hasSecretKey && userId) {
      await grantRevenueCatEntitlement(userId, plan, "monthly");
      return NextResponse.json({
        success: true,
        mode: "activated",
        plan,
        userId,
        message: `Successfully granted ${plan} entitlement in RevenueCat for user ${userId}.`,
      });
    }

    return NextResponse.json({
      mode: "demo",
      plan,
      userId: userId || "anonymous",
      email: email || "listener@audioby.app",
      message:
        "Whop is not configured yet. Set WHOP_API_KEY, WHOP_PLUS_PLAN_ID, and WHOP_PREMIUM_PLAN_ID.",
    });
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : "Internal Server Error";
    return NextResponse.json({ error: message }, { status: 500 });
  }
}
