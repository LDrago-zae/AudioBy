"use client";

import React, { useState } from "react";
import { motion, AnimatePresence } from "motion/react";
import { Check, ArrowRight } from "lucide-react";

interface PricingSectionProps {
  onSelectPlan: (plan: "plus" | "premium") => void;
}

export const PricingSection: React.FC<PricingSectionProps> = ({ onSelectPlan }) => {
  const [isAnnual, setIsAnnual] = useState(false);

  const plusPrice = isAnnual ? "$3.99" : "$4.99";
  const plusPeriod = isAnnual ? "/ month, billed annually" : "/ month";

  const premiumPrice = isAnnual ? "$7.99" : "$9.99";
  const premiumPeriod = isAnnual ? "/ month, billed annually" : "/ month";

  return (
    <section id="pricing" className="py-14 sm:py-20 md:py-24 border-t border-black/[0.08] dark:border-white/[0.08] bg-[#F8FAF8] dark:bg-[#08090B] relative transition-colors duration-200">
      <div className="mx-auto max-w-6xl px-3.5 sm:px-6">
        {/* Header */}
        <div className="text-center max-w-2xl mx-auto mb-8 sm:mb-10">
          <motion.div
            initial={{ opacity: 0, y: -10 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            className="flex items-center justify-center gap-2 mb-3 text-[11px] font-mono tracking-wider uppercase text-zinc-500 dark:text-zinc-400"
          >
            <span className="font-bold text-[#059669] dark:text-[#10B981]">[ 05 ]</span>
            <span className="font-semibold text-zinc-700 dark:text-zinc-300">HONEST, AUDITABLE PRICING</span>
          </motion.div>

          <motion.h2
            initial={{ opacity: 0, y: 14 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ delay: 0.1 }}
            className="text-2xl sm:text-4xl md:text-5xl font-bold tracking-tight text-zinc-950 dark:text-white"
          >
            Public classics are free.
            <br />
            <span className="text-zinc-500 dark:text-zinc-400 font-normal block sm:inline">
              PDF imports & ElevenLabs studio voices are subscription.
            </span>
          </motion.h2>

          <motion.p
            initial={{ opacity: 0, y: 14 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ delay: 0.2 }}
            className="mt-2.5 sm:mt-3 text-xs sm:text-base text-zinc-600 dark:text-zinc-400"
          >
            Activate once on the web. Entitlements sync across both web and the native iOS App.
          </motion.p>
        </div>

        {/* Monthly / Annual Toggle */}
        <div className="flex items-center justify-center gap-2.5 sm:gap-3 mb-8 sm:mb-14">
          <button
            onClick={() => setIsAnnual(false)}
            className={`text-xs font-mono tracking-wider uppercase transition-colors ${!isAnnual ? "text-zinc-950 dark:text-white font-bold" : "text-zinc-500 dark:text-zinc-500"}`}
          >
            Monthly
          </button>

          <button
            onClick={() => setIsAnnual(!isAnnual)}
            className="relative h-6 w-11 rounded-full bg-zinc-200 dark:bg-[#161922] border border-black/[0.08] dark:border-white/[0.1] p-0.5 transition-colors cursor-pointer"
            aria-label="Toggle annual billing"
          >
            <motion.div
              className="h-4 w-4 rounded-full bg-[#10B981]"
              animate={{ x: isAnnual ? 20 : 0 }}
              transition={{ type: "spring", stiffness: 500, damping: 30 }}
            />
          </button>

          <div className="flex items-center gap-1.5">
            <button
              onClick={() => setIsAnnual(true)}
              className={`text-xs font-mono tracking-wider uppercase transition-colors ${isAnnual ? "text-zinc-950 dark:text-white font-bold" : "text-zinc-500 dark:text-zinc-500"}`}
            >
              Annual
            </button>
            <span className="rounded bg-[#10B981]/15 px-2 py-0.5 font-mono text-[10px] text-[#059669] dark:text-[#10B981] border border-[#10B981]/30 font-semibold uppercase">
              Save 20%
            </span>
          </div>
        </div>

        {/* Pricing Cards */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-5 sm:gap-6 items-stretch">
          {/* FREE PLAN */}
          <motion.div
            initial={{ opacity: 0, y: 24 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.5, delay: 0.1 }}
            whileHover={{ y: -4, transition: { duration: 0.2 } }}
            className="flex flex-col justify-between rounded-2xl border border-black/[0.08] dark:border-white/[0.08] bg-white dark:bg-[#0E1015] p-5 sm:p-7 shadow-sm dark:shadow-tactile hover:border-black/20 dark:hover:border-white/20 transition-colors"
          >
            <div>
              <div className="flex items-center justify-between mb-2">
                <h3 className="text-base sm:text-lg font-bold text-zinc-950 dark:text-white">Free Starter</h3>
                <span className="text-[10px] font-mono uppercase text-zinc-500 dark:text-zinc-400 border border-black/[0.08] dark:border-white/[0.08] px-2 py-0.5 rounded bg-zinc-100 dark:bg-[#14171E]">
                  Perpetual
                </span>
              </div>
              <p className="text-xs text-zinc-600 dark:text-zinc-400 mb-5 sm:mb-6 leading-relaxed">
                Stream 70,000+ public domain classics with standard playback controls and local bookmarks.
              </p>

              <div className="flex items-baseline gap-1 mb-5 sm:mb-6 pb-5 sm:pb-6 border-b border-black/[0.06] dark:border-white/[0.06]">
                <span className="text-3xl sm:text-4xl font-mono font-bold text-zinc-950 dark:text-white">$0</span>
                <span className="text-xs font-mono text-zinc-500 dark:text-zinc-500">forever</span>
              </div>

              <div className="space-y-2.5 sm:space-y-3 text-xs text-zinc-800 dark:text-zinc-300">
                <div className="flex items-center gap-2.5">
                  <Check className="h-4 w-4 text-[#059669] dark:text-[#10B981] shrink-0" />
                  <span>70,000+ public domain audiobooks</span>
                </div>
                <div className="flex items-center gap-2.5">
                  <Check className="h-4 w-4 text-[#059669] dark:text-[#10B981] shrink-0" />
                  <span>1 custom PDF document import</span>
                </div>
                <div className="flex items-center gap-2.5">
                  <Check className="h-4 w-4 text-[#059669] dark:text-[#10B981] shrink-0" />
                  <span>1 offline book download</span>
                </div>
                <div className="flex items-center gap-2.5">
                  <Check className="h-4 w-4 text-[#059669] dark:text-[#10B981] shrink-0" />
                  <span>On-device neural speech synthesis</span>
                </div>
              </div>
            </div>

            <motion.a
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
              href="https://apps.apple.com/app/audioby/id6807599877"
              target="_blank"
              rel="noreferrer"
              className="mt-6 sm:mt-8 flex w-full items-center justify-center rounded-xl border border-black/[0.08] dark:border-white/[0.1] bg-zinc-100 dark:bg-[#14171E] py-2.5 sm:py-3 text-xs font-semibold text-zinc-950 dark:text-white hover:bg-zinc-200 dark:hover:bg-[#1A1E26] transition-colors"
            >
              Get Free on App Store
            </motion.a>
          </motion.div>

          {/* PLUS PLAN */}
          <motion.div
            initial={{ opacity: 0, y: 24 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.5, delay: 0.2 }}
            whileHover={{ y: -4, transition: { duration: 0.2 } }}
            className="flex flex-col justify-between rounded-2xl border border-black/[0.08] dark:border-white/[0.08] bg-white dark:bg-[#0E1015] p-5 sm:p-7 shadow-sm dark:shadow-tactile hover:border-black/20 dark:hover:border-white/20 transition-colors"
          >
            <div>
              <div className="flex items-center justify-between mb-2">
                <h3 className="text-base sm:text-lg font-bold text-zinc-950 dark:text-white">Plus</h3>
                <span className="text-[10px] font-mono uppercase text-[#059669] dark:text-[#10B981] border border-[#10B981]/30 bg-[#10B981]/10 px-2 py-0.5 rounded font-semibold">
                  Power Reader
                </span>
              </div>
              <p className="text-xs text-zinc-600 dark:text-zinc-400 mb-5 sm:mb-6 leading-relaxed">
                For researchers and students who import continuous articles and need limitless offline storage.
              </p>

              <div className="flex flex-col mb-5 sm:mb-6 pb-5 sm:pb-6 border-b border-black/[0.06] dark:border-white/[0.06] min-h-[64px] sm:min-h-[74px]">
                <AnimatePresence mode="wait">
                  <motion.div
                    key={plusPrice}
                    initial={{ opacity: 0, y: -4 }}
                    animate={{ opacity: 1, y: 0 }}
                    exit={{ opacity: 0, y: 4 }}
                    transition={{ duration: 0.15 }}
                    className="flex items-baseline gap-1"
                  >
                    <span className="text-3xl sm:text-4xl font-mono font-bold text-zinc-950 dark:text-white">{plusPrice}</span>
                  </motion.div>
                </AnimatePresence>
                <span className="text-[10px] sm:text-[11px] font-mono text-zinc-500 dark:text-zinc-500 mt-0.5">{plusPeriod}</span>
              </div>

              <div className="space-y-2.5 sm:space-y-3 text-xs text-zinc-800 dark:text-zinc-300">
                <div className="flex items-center gap-2.5 font-medium text-zinc-950 dark:text-white">
                  <Check className="h-4 w-4 text-[#059669] dark:text-[#10B981] shrink-0" />
                  <span>Unlimited PDF & document imports</span>
                </div>
                <div className="flex items-center gap-2.5 font-medium text-zinc-950 dark:text-white">
                  <Check className="h-4 w-4 text-[#059669] dark:text-[#10B981] shrink-0" />
                  <span>Unlimited offline book downloads</span>
                </div>
                <div className="flex items-center gap-2.5">
                  <Check className="h-4 w-4 text-[#059669] dark:text-[#10B981] shrink-0" />
                  <span>On-device speech engine</span>
                </div>
                <div className="flex items-center gap-2.5">
                  <Check className="h-4 w-4 text-[#059669] dark:text-[#10B981] shrink-0" />
                  <span>Universal Web & iOS entitlement sync</span>
                </div>
              </div>
            </div>

            <motion.button
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
              onClick={() => onSelectPlan("plus")}
              className="mt-6 sm:mt-8 flex w-full items-center justify-center gap-1.5 rounded-xl border border-black/[0.08] dark:border-white/[0.1] bg-zinc-100 dark:bg-[#14171E] py-2.5 sm:py-3 text-xs font-semibold text-zinc-950 dark:text-white hover:bg-zinc-200 dark:hover:bg-[#1A1E26] transition-colors"
            >
              <span>Subscribe to Plus</span>
              <ArrowRight className="h-3.5 w-3.5" />
            </motion.button>
          </motion.div>

          {/* PREMIUM PLAN */}
          <motion.div
            initial={{ opacity: 0, y: 24 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.5, delay: 0.3 }}
            whileHover={{ y: -4, transition: { duration: 0.2 } }}
            className="relative flex flex-col justify-between rounded-2xl border-2 border-[#059669] dark:border-[#10B981] bg-white dark:bg-[#12151D] p-5 sm:p-7 shadow-lg dark:shadow-console transition-colors"
          >
            {/* High-craft badge */}
            <div className="absolute -top-3 left-6 rounded-full bg-[#10B981] px-3 py-0.5 text-[10px] font-bold uppercase tracking-wider text-black font-mono shadow-sm">
              Preferred Tier
            </div>

            <div>
              <div className="flex items-center justify-between mb-2">
                <h3 className="text-base sm:text-lg font-bold text-zinc-950 dark:text-white">Premium</h3>
                <span className="text-[10px] font-mono uppercase text-[#059669] dark:text-[#10B981] font-semibold">
                  ElevenLabs Studio
                </span>
              </div>
              <p className="text-xs text-zinc-600 dark:text-zinc-400 mb-5 sm:mb-6 leading-relaxed">
                Full neural acoustic experience. Human-level emotional inflections, natural pauses, and breath modeling.
              </p>

              <div className="flex flex-col mb-5 sm:mb-6 pb-5 sm:pb-6 border-b border-black/[0.06] dark:border-white/[0.06] min-h-[64px] sm:min-h-[74px]">
                <AnimatePresence mode="wait">
                  <motion.div
                    key={premiumPrice}
                    initial={{ opacity: 0, y: -4 }}
                    animate={{ opacity: 1, y: 0 }}
                    exit={{ opacity: 0, y: 4 }}
                    transition={{ duration: 0.15 }}
                    className="flex items-baseline gap-1"
                  >
                    <span className="text-3xl sm:text-4xl font-mono font-bold text-zinc-950 dark:text-white">{premiumPrice}</span>
                  </motion.div>
                </AnimatePresence>
                <span className="text-[10px] sm:text-[11px] font-mono text-zinc-500 dark:text-zinc-500 mt-0.5">{premiumPeriod}</span>
              </div>

              <div className="space-y-2.5 sm:space-y-3 text-xs text-zinc-800 dark:text-zinc-300">
                <div className="flex items-center gap-2.5 font-semibold text-[#059669] dark:text-[#10B981]">
                  <Check className="h-4 w-4 shrink-0 text-[#059669] dark:text-[#10B981]" />
                  <span>ElevenLabs AI Neural voices included</span>
                </div>
                <div className="flex items-center gap-2.5 font-medium text-zinc-950 dark:text-white">
                  <Check className="h-4 w-4 text-[#059669] dark:text-[#10B981] shrink-0" />
                  <span>Studio narration: Adam, Rachel & more</span>
                </div>
                <div className="flex items-center gap-2.5 font-medium text-zinc-950 dark:text-white">
                  <Check className="h-4 w-4 text-[#059669] dark:text-[#10B981] shrink-0" />
                  <span>Unlimited PDF & document imports</span>
                </div>
                <div className="flex items-center gap-2.5 font-medium text-zinc-950 dark:text-white">
                  <Check className="h-4 w-4 text-[#059669] dark:text-[#10B981] shrink-0" />
                  <span>Unlimited offline storage</span>
                </div>
                <div className="flex items-center gap-2.5">
                  <Check className="h-4 w-4 text-[#059669] dark:text-[#10B981] shrink-0" />
                  <span>Priority neural voice server bandwidth</span>
                </div>
              </div>
            </div>

            <motion.button
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
              onClick={() => onSelectPlan("premium")}
              className="mt-6 sm:mt-8 flex w-full items-center justify-center gap-1.5 rounded-xl bg-[#10B981] hover:bg-[#059669] dark:hover:bg-[#34D399] py-2.5 sm:py-3 text-xs font-semibold text-black transition-all shadow-sm"
            >
              <span>Subscribe to Premium</span>
              <ArrowRight className="h-3.5 w-3.5" />
            </motion.button>
          </motion.div>
        </div>
      </div>
    </section>
  );
};
