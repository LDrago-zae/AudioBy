import { NextResponse } from "next/server";
import { getRevenueCatSubscriber } from "@/lib/revenuecat-admin";

export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const userId = searchParams.get("userId");

    if (!userId) {
      return NextResponse.json({ error: "Missing userId parameter" }, { status: 400 });
    }

    const subscriberData = await getRevenueCatSubscriber(userId);
    const entitlements = subscriberData?.subscriber?.entitlements || {};

    const isPremium = Boolean(entitlements["premium"]);
    const isPlus = Boolean(entitlements["plus"]) || isPremium;

    return NextResponse.json({
      userId,
      tier: isPremium ? "premium" : isPlus ? "plus" : "free",
      isPlus,
      isPremium,
      entitlements,
    });
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : "Status fetch error";
    return NextResponse.json({ error: message }, { status: 500 });
  }
}
