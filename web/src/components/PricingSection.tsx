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
    <section id="pricing" className="py-14 sm:py-20 md:py-24 border-t border-black/[0.08] dark:border-white/[0.08] bg-[#F9FAF9] dark:bg-[#0C100E] relative transition-colors duration-200">
      <div className="mx-auto max-w-6xl px-3.5 sm:px-6">
        {/* Header */}
        <div className="text-center max-w-2xl mx-auto mb-8 sm:mb-10">
          <motion.div
            initial={{ opacity: 0, y: -10 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            className="inline-flex items-center gap-2 mb-3 text-[10px] font-mono tracking-eyebrow uppercase text-[#0F9B51] dark:text-emerald"
          >
            <span className="h-1.5 w-1.5 rounded-full bg-emerald animate-pulse" />
            <span>Fair, Transparent Pricing</span>
          </motion.div>

          <motion.h2
            initial={{ opacity: 0, y: 14 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ delay: 0.1 }}
            className="text-2xl sm:text-4xl md:text-5xl font-bold tracking-tight text-zinc-900 dark:text-white"
          >
            Streaming is free.
            <br />
            <span className="text-zinc-600 dark:text-ink-secondary font-normal block sm:inline">
              PDF imports & studio voices are the paid part.
            </span>
          </motion.h2>

          <motion.p
            initial={{ opacity: 0, y: 14 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ delay: 0.2 }}
            className="mt-2.5 sm:mt-3 text-xs sm:text-sm text-zinc-600 dark:text-ink-secondary"
          >
            Subscribe once on the web. Your account syncs instantly to AudioBy on the iOS App Store.
          </motion.p>
        </div>

        {/* Monthly / Annual Toggle with animated switch */}
        <div className="flex items-center justify-center gap-2.5 sm:gap-3 mb-8 sm:mb-14">
          <button
            onClick={() => setIsAnnual(false)}
            className={`text-xs font-medium transition-colors ${!isAnnual ? "text-zinc-900 dark:text-white font-bold" : "text-zinc-500 dark:text-ink-muted"}`}
          >
            Monthly
          </button>

          <button
            onClick={() => setIsAnnual(!isAnnual)}
            className="relative h-6 w-11 rounded-full bg-[#E2E8E2] dark:bg-[#1B231E] border border-black/[0.08] dark:border-white/10 p-0.5 transition-colors"
            aria-label="Toggle annual billing"
          >
            <motion.div
              className="h-4 w-4 rounded-full bg-emerald"
              animate={{ x: isAnnual ? 20 : 0 }}
              transition={{ type: "spring", stiffness: 500, damping: 30 }}
            />
          </button>

          <div className="flex items-center gap-1.5">
            <button
              onClick={() => setIsAnnual(true)}
              className={`text-xs font-medium transition-colors ${isAnnual ? "text-zinc-900 dark:text-white font-bold" : "text-zinc-500 dark:text-ink-muted"}`}
            >
              Yearly
            </button>
            <span className="rounded bg-emerald/15 px-2 py-0.5 font-mono text-[10px] text-[#0F9B51] dark:text-emerald border border-emerald/30 font-semibold">
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
            whileHover={{ y: -6, transition: { duration: 0.2 } }}
            className="flex flex-col justify-between rounded-2xl border border-black/[0.08] dark:border-white/10 bg-white dark:bg-[#121714] p-5 sm:p-7 shadow-sm dark:shadow-card hover:border-black/20 dark:hover:border-white/20 transition-colors"
          >
            <div>
              <div className="flex items-center justify-between mb-2">
                <h3 className="text-base sm:text-lg font-bold text-zinc-900 dark:text-white">Free Starter</h3>
                <span className="text-[10px] font-mono uppercase text-zinc-500 dark:text-ink-muted border border-black/[0.08] dark:border-white/10 px-2 py-0.5 rounded bg-[#F0F4F0] dark:bg-[#161D19]">
                  Forever
                </span>
              </div>
              <p className="text-xs text-zinc-600 dark:text-ink-secondary mb-5 sm:mb-6 leading-relaxed">
                Stream public classics with standard playback controls and local chapter bookmarks.
              </p>

              <div className="flex items-baseline gap-1 mb-5 sm:mb-6 pb-5 sm:pb-6 border-b border-black/[0.06] dark:border-white/[0.06]">
                <span className="text-3xl sm:text-4xl font-mono font-bold text-zinc-900 dark:text-white">$0</span>
                <span className="text-xs font-mono text-zinc-500 dark:text-ink-muted">forever</span>
              </div>

              <div className="space-y-2.5 sm:space-y-3 text-xs text-zinc-800 dark:text-ink-primary">
                <div className="flex items-center gap-2.5">
                  <Check className="h-4 w-4 text-[#0F9B51] dark:text-emerald shrink-0" />
                  <span>70,000+ public domain audiobooks</span>
                </div>
                <div className="flex items-center gap-2.5">
                  <Check className="h-4 w-4 text-[#0F9B51] dark:text-emerald shrink-0" />
                  <span>1 custom PDF document import</span>
                </div>
                <div className="flex items-center gap-2.5">
                  <Check className="h-4 w-4 text-[#0F9B51] dark:text-emerald shrink-0" />
                  <span>1 offline book download</span>
                </div>
                <div className="flex items-center gap-2.5">
                  <Check className="h-4 w-4 text-[#0F9B51] dark:text-emerald shrink-0" />
                  <span>On-device speech synthesis</span>
                </div>
              </div>
            </div>

            <motion.a
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
              href="https://apps.apple.com/app/audioby/id6807599877"
              target="_blank"
              rel="noreferrer"
              className="mt-6 sm:mt-8 flex w-full items-center justify-center rounded-xl border border-black/[0.08] dark:border-white/10 bg-[#F0F4F0] dark:bg-[#161D19] py-2.5 sm:py-3 text-xs font-semibold text-zinc-900 dark:text-white hover:bg-[#E4EAE4] dark:hover:bg-[#1B231E] transition-colors"
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
            whileHover={{ y: -6, transition: { duration: 0.2 } }}
            className="flex flex-col justify-between rounded-2xl border border-black/[0.08] dark:border-white/10 bg-white dark:bg-[#121714] p-5 sm:p-7 shadow-sm dark:shadow-card hover:border-[#0F9B51]/40 dark:hover:border-emerald/40 transition-colors"
          >
            <div>
              <div className="flex items-center justify-between mb-2">
                <h3 className="text-base sm:text-lg font-bold text-zinc-900 dark:text-white">Plus</h3>
                <span className="text-[10px] font-mono uppercase text-[#0F9B51] dark:text-emerald border border-emerald/30 dark:border-emerald/20 px-2 py-0.5 rounded bg-emerald/10 font-semibold">
                  Power Reader
                </span>
              </div>
              <p className="text-xs text-zinc-600 dark:text-ink-secondary mb-5 sm:mb-6 leading-relaxed">
                For researchers, students, and avid readers who import documents and listen offline.
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
                    <span className="text-3xl sm:text-4xl font-mono font-bold text-zinc-900 dark:text-white">{plusPrice}</span>
                  </motion.div>
                </AnimatePresence>
                <span className="text-[10px] sm:text-[11px] font-mono text-zinc-500 dark:text-ink-muted mt-0.5">{plusPeriod}</span>
              </div>

              <div className="space-y-2.5 sm:space-y-3 text-xs text-zinc-800 dark:text-ink-primary">
                <div className="flex items-center gap-2.5 font-medium text-zinc-900 dark:text-white">
                  <Check className="h-4 w-4 text-[#0F9B51] dark:text-emerald shrink-0" />
                  <span>Unlimited PDF & document imports</span>
                </div>
                <div className="flex items-center gap-2.5 font-medium text-zinc-900 dark:text-white">
                  <Check className="h-4 w-4 text-[#0F9B51] dark:text-emerald shrink-0" />
                  <span>Unlimited offline book downloads</span>
                </div>
                <div className="flex items-center gap-2.5">
                  <Check className="h-4 w-4 text-[#0F9B51] dark:text-emerald shrink-0" />
                  <span>On-device speech engine</span>
                </div>
                <div className="flex items-center gap-2.5">
                  <Check className="h-4 w-4 text-[#0F9B51] dark:text-emerald shrink-0" />
                  <span>Universal Web & iOS entitlement sync</span>
                </div>
              </div>
            </div>

            <motion.button
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
              onClick={() => onSelectPlan("plus")}
              className="mt-6 sm:mt-8 flex w-full items-center justify-center gap-1.5 rounded-xl border border-black/[0.08] dark:border-white/10 bg-[#F0F4F0] dark:bg-[#161D19] py-2.5 sm:py-3 text-xs font-semibold text-zinc-900 dark:text-white hover:bg-[#E4EAE4] dark:hover:bg-[#1B231E] transition-colors"
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
            whileHover={{ y: -6, transition: { duration: 0.2 } }}
            className="relative flex flex-col justify-between rounded-2xl border-2 border-[#0F9B51] dark:border-emerald bg-white dark:bg-[#161D19] p-5 sm:p-7 shadow-lg dark:shadow-elevated transition-colors"
          >
            {/* Badge */}
            <div className="absolute -top-3 left-6 rounded-full bg-emerald px-3 py-0.5 text-[10px] font-bold uppercase tracking-wider text-black font-mono">
              Most Popular
            </div>

            <div>
              <div className="flex items-center justify-between mb-2">
                <h3 className="text-base sm:text-lg font-bold text-zinc-900 dark:text-white">Premium</h3>
                <span className="text-[10px] font-mono uppercase text-[#0F9B51] dark:text-emerald font-semibold">
                  ElevenLabs
                </span>
              </div>
              <p className="text-xs text-zinc-600 dark:text-ink-secondary mb-5 sm:mb-6 leading-relaxed">
                The definitive audiobook experience with studio-grade neural narration and human breath.
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
                    <span className="text-3xl sm:text-4xl font-mono font-bold text-zinc-900 dark:text-white">{premiumPrice}</span>
                  </motion.div>
                </AnimatePresence>
                <span className="text-[10px] sm:text-[11px] font-mono text-zinc-500 dark:text-ink-muted mt-0.5">{premiumPeriod}</span>
              </div>

              <div className="space-y-2.5 sm:space-y-3 text-xs text-zinc-800 dark:text-white">
                <div className="flex items-center gap-2.5 font-semibold text-[#0F9B51] dark:text-emerald">
                  <Check className="h-4 w-4 text-[#0F9B51] dark:text-emerald shrink-0" />
                  <span>Everything in Plus included</span>
                </div>
                <div className="flex items-center gap-2.5 font-medium text-zinc-900 dark:text-white">
                  <Check className="h-4 w-4 text-[#0F9B51] dark:text-emerald shrink-0" />
                  <span>ElevenLabs studio neural actors</span>
                </div>
                <div className="flex items-center gap-2.5 font-medium text-zinc-900 dark:text-white">
                  <Check className="h-4 w-4 text-[#0F9B51] dark:text-emerald shrink-0" />
                  <span>Cached neural narration for offline</span>
                </div>
                <div className="flex items-center gap-2.5 font-medium text-zinc-900 dark:text-white">
                  <Check className="h-4 w-4 text-[#0F9B51] dark:text-emerald shrink-0" />
                  <span>Natural speech cadence & breathing</span>
                </div>
              </div>
            </div>

            <motion.button
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
              onClick={() => onSelectPlan("premium")}
              className="mt-6 sm:mt-8 flex w-full items-center justify-center gap-1.5 rounded-xl bg-emerald py-2.5 sm:py-3 text-xs font-bold text-black hover:bg-emerald-light transition-colors shadow-md"
            >
              <span>Get Premium Now</span>
              <ArrowRight className="h-3.5 w-3.5" />
            </motion.button>
          </motion.div>
        </div>

        <p className="mt-6 sm:mt-8 text-center text-[11px] sm:text-xs text-zinc-500 dark:text-ink-muted">
          Cancel in two clicks anytime before renewal. Zero hidden commitments.
        </p>
      </div>
    </section>
  );
};
