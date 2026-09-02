import { NextResponse } from "next/server";

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { plan, userId, email } = body;

    if (plan !== "plus" && plan !== "premium") {
      return NextResponse.json({ error: "Invalid plan specified." }, { status: 400 });
    }

    const plusUrl = process.env.NEXT_PUBLIC_STRIPE_PLUS_URL;
    const premiumUrl = process.env.NEXT_PUBLIC_STRIPE_PREMIUM_URL;
    const targetUrl = plan === "premium" ? premiumUrl : plusUrl;

    if (targetUrl) {
      const url = new URL(targetUrl);
      if (userId) {
        url.searchParams.set("client_reference_id", userId);
      }
      if (email) {
        url.searchParams.set("prefilled_email", email);
      }
      return NextResponse.json({ url: url.toString() });
    }

    // In demo/test mode when custom Stripe links are not yet set
    return NextResponse.json({
      mode: "demo",
      plan,
      userId: userId || "anonymous",
      email: email || "listener@audioby.app",
      message: "Ready for Stripe / RevenueCat live checkout.",
    });
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : "Internal Server Error";
    return NextResponse.json({ error: message }, { status: 500 });
  }
}
