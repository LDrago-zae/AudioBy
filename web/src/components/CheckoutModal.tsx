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
            className="relative w-full max-w-md rounded-2xl border border-black/10 dark:border-white/10 bg-white dark:bg-[#161D17] p-5 sm:p-6 shadow-2xl z-10 max-h-[92vh] overflow-y-auto transition-colors"
          >
            {/* Close Button */}
            <button
              onClick={() => {
                setSuccess(false);
                onClose();
              }}
              className="absolute right-4 top-4 rounded-lg p-1 text-zinc-400 hover:bg-black/[0.04] dark:hover:bg-[#1A211B] hover:text-zinc-800 dark:hover:text-white transition-colors"
            >
              <X className="h-4 w-4" />
            </button>

            {!success ? (
              <div>
                <div className="mb-4">
                  <h3 className="text-xl font-bold text-zinc-900 dark:text-white">Subscribe to {planName}</h3>
                  <p className="mt-1 text-xs text-zinc-600 dark:text-slate-400">
                    Unlock full access across your web browser and the AudioBy iOS app.
                  </p>
                </div>

                {/* Plan card summary */}
                <div className="rounded-xl border border-black/[0.08] dark:border-white/10 bg-[#F6FAF6] dark:bg-[#1A211B] p-4 mb-4">
                  <div className="flex items-center justify-between pb-3 border-b border-black/[0.06] dark:border-white/5 mb-3">
                    <span className="text-sm font-bold text-zinc-900 dark:text-white">{planName}</span>
                    <span className="text-base font-bold text-[#0F9B51] dark:text-emerald font-mono">{planPrice} / mo</span>
                  </div>

                  <div className="space-y-2 text-xs text-zinc-700 dark:text-slate-300">
                    {plan === "premium" ? (
                      <>
                        <div className="flex items-center gap-2">
                          <Check className="h-3.5 w-3.5 text-[#0F9B51] dark:text-emerald shrink-0" />
                          <span>ElevenLabs studio voices & neural synthesis</span>
                        </div>
                        <div className="flex items-center gap-2">
                          <Check className="h-3.5 w-3.5 text-[#0F9B51] dark:text-emerald shrink-0" />
                          <span>Unlimited PDF and document uploads</span>
                        </div>
                        <div className="flex items-center gap-2">
                          <Check className="h-3.5 w-3.5 text-[#0F9B51] dark:text-emerald shrink-0" />
                          <span>Unlimited offline book downloads</span>
                        </div>
                      </>
                    ) : (
                      <>
                        <div className="flex items-center gap-2">
                          <Check className="h-3.5 w-3.5 text-[#0F9B51] dark:text-emerald shrink-0" />
                          <span>Unlimited PDF and document uploads</span>
                        </div>
                        <div className="flex items-center gap-2">
                          <Check className="h-3.5 w-3.5 text-[#0F9B51] dark:text-emerald shrink-0" />
                          <span>Unlimited offline book downloads</span>
                        </div>
                        <div className="flex items-center gap-2">
                          <Check className="h-3.5 w-3.5 text-[#0F9B51] dark:text-emerald shrink-0" />
                          <span>On-device speech synthesis engine</span>
                        </div>
                      </>
                    )}
                  </div>
                </div>

                {/* Account row */}
                <div className="rounded-xl border border-black/[0.06] dark:border-white/5 bg-[#F0F4F0] dark:bg-[#0D150F] p-3 text-xs mb-5 flex items-center justify-between">
                  <span className="text-zinc-600 dark:text-slate-400">Purchasing for:</span>
                  {user ? (
                    <span className="font-medium text-zinc-900 dark:text-white flex items-center gap-1.5 font-mono">
                      <span className="h-1.5 w-1.5 rounded-full bg-emerald" />
                      {user.email}
                    </span>
                  ) : (
                    <button
                      onClick={onRequireAuth}
                      className="font-medium text-[#0F9B51] dark:text-emerald hover:underline"
                    >
                      Sign in first
                    </button>
                  )}
                </div>

                {/* Action button */}
                <motion.button
                  whileHover={{ scale: 1.02 }}
                  whileTap={{ scale: 0.98 }}
                  onClick={handleProceed}
                  disabled={loading}
                  className="flex w-full items-center justify-center gap-2 rounded-xl bg-emerald py-3 text-xs font-bold text-black hover:bg-emerald-light transition-colors disabled:opacity-50 shadow-md"
                >
                  {loading ? (
                    <Loader2 className="h-4 w-4 animate-spin text-black" />
                  ) : user ? (
                    <>
                      <span>Proceed to Payment</span>
                      <ArrowRight className="h-3.5 w-3.5" />
                    </>
                  ) : (
                    <span>Sign in to continue</span>
                  )}
                </motion.button>

                <div className="mt-4 flex items-center justify-center gap-1.5 text-[11px] text-zinc-500 dark:text-slate-500">
                  <ShieldCheck className="h-3.5 w-3.5 text-[#0F9B51] dark:text-emerald" />
                  <span>Encrypted checkout. Cancel anytime with no commitments.</span>
                </div>
              </div>
            ) : (
              /* Confirmation State */
              <div className="py-2 text-center">
                <motion.div
                  initial={{ scale: 0.5, opacity: 0 }}
                  animate={{ scale: 1, opacity: 1 }}
                  transition={{ type: "spring", stiffness: 400, damping: 20 }}
                  className="mx-auto flex h-12 w-12 items-center justify-center rounded-xl bg-emerald/10 text-[#0F9B51] dark:text-emerald border border-emerald/20 mb-4"
                >
                  <Check className="h-6 w-6" />
                </motion.div>

                <h3 className="text-xl font-bold text-zinc-900 dark:text-white">Subscription Confirmed</h3>
                <p className="mt-1.5 text-xs text-zinc-600 dark:text-slate-400">
                  Your <strong className="text-zinc-900 dark:text-white">{planName}</strong> plan has been activated for{" "}
                  <strong className="text-zinc-900 dark:text-white font-mono">{user?.email}</strong>.
                </p>

                <div className="mt-5 rounded-xl border border-black/[0.08] dark:border-white/10 bg-[#F6FAF6] dark:bg-[#1A211B] p-4 text-left">
                  <p className="text-xs font-semibold text-zinc-900 dark:text-white mb-2 flex items-center gap-1.5">
                    <Smartphone className="h-4 w-4 text-[#0F9B51] dark:text-emerald" />
                    <span>Next Step: Open AudioBy on iOS</span>
                  </p>
                  <p className="text-xs text-zinc-600 dark:text-slate-400 leading-relaxed">
                    Log into AudioBy on your iPhone with this account. Your privileges and unlimited access will sync automatically.
                  </p>
                </div>

                <motion.a
                  whileHover={{ scale: 1.02 }}
                  whileTap={{ scale: 0.98 }}
                  href="https://apps.apple.com/app/audioby/id6807599877"
                  target="_blank"
                  rel="noreferrer"
                  className="mt-5 inline-flex w-full items-center justify-center gap-1.5 rounded-xl bg-emerald py-2.5 text-xs font-bold text-black hover:bg-emerald-light transition-colors shadow-md"
                >
                  <span>Download on the App Store</span>
                  <ArrowRight className="h-3.5 w-3.5" />
                </motion.a>
              </div>
            )}
          </motion.div>
        </div>
      )}
    </AnimatePresence>
  );
};
