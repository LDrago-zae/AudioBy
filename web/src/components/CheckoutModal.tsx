"use client";

import React, { useState } from "react";
import { motion, AnimatePresence } from "motion/react";
import { X, Check, ArrowRight, Loader2, Smartphone, ShieldCheck } from "lucide-react";
import { useAuth } from "@/lib/auth-context";

interface CheckoutModalProps {
  isOpen: boolean;
  plan: "plus" | "premium" | null;
  onClose: () => void;
  onRequireAuth: () => void;
}

export const CheckoutModal: React.FC<CheckoutModalProps> = ({
  isOpen,
  plan,
  onClose,
  onRequireAuth,
}) => {
  const { user } = useAuth();
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState(false);

  if (!plan) return null;

  const planName = plan === "premium" ? "Premium Monthly" : "Plus Monthly";
  const planPrice = plan === "premium" ? "$9.99" : "$4.99";

  const handleProceed = async () => {
    if (!user) {
      onRequireAuth();
      return;
    }

    setLoading(true);
    try {
      const res = await fetch("/api/checkout", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          plan,
          userId: user.uid,
          email: user.email,
        }),
      });

      const data = await res.json();
      if (data.url) {
        window.location.href = data.url;
        return;
      }

      setSuccess(true);
    } catch (err) {
      console.error("Checkout error:", err);
    } finally {
      setLoading(false);
    }
  };

  return (
    <AnimatePresence>
      {isOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          {/* Backdrop */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={() => {
              setSuccess(false);
              onClose();
            }}
            className="fixed inset-0 bg-black/60 dark:bg-black/80 backdrop-blur-md"
          />

          {/* Modal Container */}
          <motion.div
            initial={{ scale: 0.94, opacity: 0, y: 16 }}
            animate={{ scale: 1, opacity: 1, y: 0 }}
            exit={{ scale: 0.94, opacity: 0, y: 16 }}
            transition={{ type: "spring", stiffness: 350, damping: 25 }}
            className="relative w-full max-w-md rounded-2xl border border-black/10 dark:border-white/[0.1] bg-white dark:bg-[#0E1015] p-5 sm:p-6 shadow-2xl z-10 max-h-[92vh] overflow-y-auto transition-colors"
          >
            {/* Close Button */}
            <button
              onClick={() => {
                setSuccess(false);
                onClose();
              }}
              className="absolute right-4 top-4 rounded-lg p-1 text-zinc-400 hover:bg-black/[0.04] dark:hover:bg-[#161922] hover:text-zinc-800 dark:hover:text-white transition-colors"
            >
              <X className="h-4 w-4" />
            </button>

            {!success ? (
              <div>
                <div className="mb-4">
                  <h3 className="text-xl font-bold text-zinc-950 dark:text-white">Subscribe to {planName}</h3>
                  <p className="mt-1 text-xs text-zinc-600 dark:text-zinc-400">
                    Unlock full access across your web browser and the AudioBy iOS app.
                  </p>
                </div>

                {/* Plan card summary */}
                <div className="rounded-xl border border-black/[0.08] dark:border-white/[0.08] bg-zinc-50 dark:bg-[#14171E] p-4 mb-4">
                  <div className="flex items-center justify-between pb-3 border-b border-black/[0.06] dark:border-white/[0.06] mb-3">
                    <span className="text-sm font-bold text-zinc-950 dark:text-white">{planName}</span>
                    <span className="text-base font-bold text-[#059669] dark:text-[#10B981] font-mono">{planPrice} / mo</span>
                  </div>

                  <div className="space-y-2 text-xs text-zinc-700 dark:text-zinc-300">
                    {plan === "premium" ? (
                      <>
                        <div className="flex items-center gap-2">
                          <Check className="h-3.5 w-3.5 text-[#059669] dark:text-[#10B981] shrink-0" />
                          <span>ElevenLabs studio voices & neural synthesis</span>
                        </div>
                        <div className="flex items-center gap-2">
                          <Check className="h-3.5 w-3.5 text-[#059669] dark:text-[#10B981] shrink-0" />
                          <span>Unlimited PDF & document imports</span>
                        </div>
                        <div className="flex items-center gap-2">
                          <Check className="h-3.5 w-3.5 text-[#059669] dark:text-[#10B981] shrink-0" />
                          <span>Unlimited offline downloads</span>
                        </div>
                      </>
                    ) : (
                      <>
                        <div className="flex items-center gap-2">
                          <Check className="h-3.5 w-3.5 text-[#059669] dark:text-[#10B981] shrink-0" />
                          <span>Unlimited PDF & document imports</span>
                        </div>
                        <div className="flex items-center gap-2">
                          <Check className="h-3.5 w-3.5 text-[#059669] dark:text-[#10B981] shrink-0" />
                          <span>Unlimited offline downloads</span>
                        </div>
                      </>
                    )}
                  </div>
                </div>

                {/* Account row */}
                <div className="rounded-xl border border-black/[0.08] dark:border-white/[0.08] bg-zinc-50 dark:bg-[#12151B] p-3 mb-5 text-xs flex items-center justify-between">
                  <span className="text-zinc-500 dark:text-zinc-400">Account:</span>
                  <span className="font-mono text-zinc-900 dark:text-white font-medium">
                    {user ? user.email : "Not signed in"}
                  </span>
                </div>

                {/* iOS sync badge note */}
                <div className="flex items-start gap-2 text-[11px] text-zinc-500 dark:text-zinc-400 mb-6 bg-black/[0.02] dark:bg-[#07080A] p-2.5 rounded-lg border border-black/[0.06] dark:border-white/[0.06]">
                  <Smartphone className="h-4 w-4 text-[#059669] dark:text-[#10B981] shrink-0 mt-0.5" />
                  <span>
                    Your purchase immediately unlocks access on your iPhone. Sign into the iOS app with this same email.
                  </span>
                </div>

                {/* Proceed button */}
                <button
                  onClick={handleProceed}
                  disabled={loading}
                  className="flex w-full items-center justify-center gap-1.5 rounded-xl bg-[#10B981] hover:bg-[#059669] dark:hover:bg-[#34D399] py-3 text-xs font-semibold text-black transition-colors disabled:opacity-50 shadow-sm"
                >
                  {loading ? (
                    <Loader2 className="h-4 w-4 animate-spin" />
                  ) : (
                    <>
                      <span>{user ? `Proceed with ${planPrice}/mo` : "Sign In to Continue"}</span>
                      <ArrowRight className="h-3.5 w-3.5" />
                    </>
                  )}
                </button>
              </div>
            ) : (
              <div className="text-center py-6">
                <div className="mx-auto mb-3 flex h-12 w-12 items-center justify-center rounded-full bg-[#10B981]/20 text-[#059669] dark:text-[#10B981]">
                  <ShieldCheck className="h-6 w-6" />
                </div>
                <h3 className="text-lg font-bold text-zinc-950 dark:text-white">Subscription Active</h3>
                <p className="mt-1 text-xs text-zinc-600 dark:text-zinc-400 max-w-xs mx-auto leading-relaxed">
                  Your {planName} tier is now active and attached to {user?.email}.
                </p>
                <div className="mt-6 flex flex-col gap-2">
                  <a
                    href="https://apps.apple.com/app/audioby/id6807599877"
                    target="_blank"
                    rel="noreferrer"
                    className="flex items-center justify-center gap-1.5 rounded-xl bg-[#10B981] hover:bg-[#059669] dark:hover:bg-[#34D399] py-2.5 text-xs font-semibold text-black transition-colors"
                  >
                    <span>Open in iOS App</span>
                    <ArrowRight className="h-3.5 w-3.5" />
                  </a>
                  <button
                    onClick={() => {
                      setSuccess(false);
                      onClose();
                    }}
                    className="rounded-xl border border-black/[0.08] dark:border-white/[0.08] py-2 text-xs text-zinc-600 dark:text-zinc-400 hover:text-zinc-900 dark:hover:text-white transition-colors"
                  >
                    Close
                  </button>
                </div>
              </div>
            )}
          </motion.div>
        </div>
      )}
    </AnimatePresence>
  );
};
