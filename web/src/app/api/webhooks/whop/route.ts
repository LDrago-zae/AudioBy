import { NextResponse } from "next/server";
import {
  grantRevenueCatEntitlement,
  revokeRevenueCatEntitlement,
} from "@/lib/revenuecat-admin";
import { planFromWhopPlanId, verifyWhopWebhook, type CheckoutPlan } from "@/lib/whop";

interface WhopMembership {
  metadata?: Record<string, string | undefined> | null;
  plan?: { id?: string } | null;
  plan_id?: string;
  status?: string;
}

interface WhopEvent {
  type?: string;
  data?: WhopMembership;
}

const ACTIVE_STATUSES = new Set(["active", "trialing", "completed", "canceling", "past_due"]);

function resolvePlan(membership: WhopMembership | undefined): CheckoutPlan | null {
  const fromMeta = membership?.metadata?.plan;
  if (fromMeta === "plus" || fromMeta === "premium") return fromMeta;
  return planFromWhopPlanId(membership?.plan_id || membership?.plan?.id);
}

function firebaseUserId(membership: WhopMembership | undefined): string | undefined {
  const meta = membership?.metadata;
  return meta?.user_id || meta?.customer_id;
}

export async function POST(request: Request) {
  const rawBody = await request.text();

  try {
    verifyWhopWebhook(rawBody, request.headers);
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : "Invalid webhook";
    return NextResponse.json({ error: message }, { status: 401 });
  }

  let event: WhopEvent;
  try {
    event = JSON.parse(rawBody) as WhopEvent;
  } catch {
    return NextResponse.json({ error: "Invalid JSON" }, { status: 400 });
  }

  const type = event.type ?? "";
  const membership = event.data;
  const userId = firebaseUserId(membership);
  const plan = resolvePlan(membership);

  const isActivation = type === "membership.activated";
  const isUpdate = type === "membership.updated";
  if (!isActivation && !isUpdate) {
    return NextResponse.json({ received: true, ignored: type });
  }

  if (!userId || !plan) {
    return NextResponse.json({
      received: true,
      warning: "Missing user_id or plan on membership metadata.",
      event: type,
    });
  }

  const status = membership?.status ?? "active";
  if (isActivation || ACTIVE_STATUSES.has(status)) {
    await grantRevenueCatEntitlement(userId, plan, "monthly");
  } else {
    await revokeRevenueCatEntitlement(userId, plan);
  }

  return NextResponse.json({ received: true, event: type, userId, plan });
}
