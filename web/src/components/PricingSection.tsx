"use client";

import React, { useState } from "react";
import { Check, ArrowRight } from "lucide-react";
import { pulseTap, useScrollReveal, useSplitHeading, useSpringHover } from "@/lib/anime-motion";

interface PricingSectionProps {
  onSelectPlan: (plan: "plus" | "premium") => void;
}

export const PricingSection: React.FC<PricingSectionProps> = ({ onSelectPlan }) => {
  const [isAnnual, setIsAnnual] = useState(false);
  const revealRef = useScrollReveal<HTMLElement>();
  const springRef = useSpringHover<HTMLElement>();
  const splitRef = useSplitHeading<HTMLElement>();

  const setSectionRef = (node: HTMLElement | null) => {
    (revealRef as React.MutableRefObject<HTMLElement | null>).current = node;
    (springRef as React.MutableRefObject<HTMLElement | null>).current = node;
    (splitRef as React.MutableRefObject<HTMLElement | null>).current = node;
  };

  const plusPrice = isAnnual ? "$10" : "$14";
  const plusPeriod = isAnnual ? "/ month, billed annually" : "/ month";
  const premiumPrice = isAnnual ? "$29" : "$39";
  const premiumPeriod = isAnnual ? "/ month, billed annually" : "/ month";

  return (
    <section
      id="pricing"
      ref={setSectionRef}
      className="py-16 sm:py-24 border-t border-[var(--border-subtle)] bg-[var(--background)]"
    >
      <div className="mx-auto max-w-6xl px-4 sm:px-6">
        <div className="text-center max-w-2xl mx-auto mb-10 sm:mb-12">
          <h2
            data-split
            className="font-display text-3xl sm:text-5xl font-bold tracking-tight text-leaf-ink leading-tight"
          >
            Public classics are free.
          </h2>
          <p
            data-reveal
            className="mt-3 text-leaf-muted font-semibold text-xl sm:text-3xl font-display"
          >
            PDF imports & ElevenLabs studio voices are subscription.
          </p>
          <p data-reveal className="mt-4 text-sm sm:text-base text-leaf-muted">
            Activate once on the web. Entitlements sync across web and the native iOS app.
          </p>
        </div>

        <div data-reveal className="flex items-center justify-center gap-3 mb-10 sm:mb-14">
          <button
            type="button"
            onClick={() => setIsAnnual(false)}
            className={`text-sm font-semibold transition-colors ${!isAnnual ? "text-leaf-ink" : "text-leaf-faint"}`}
          >
            Monthly
          </button>
          <button
            type="button"
            onClick={() => setIsAnnual(!isAnnual)}
            className="relative h-7 w-12 rounded-full bg-black/10 dark:bg-white/10 p-0.5 transition-colors"
            aria-label="Toggle annual billing"
          >
            <span
              className={`block h-6 w-6 rounded-full bg-emerald transition-transform ${isAnnual ? "translate-x-5" : "translate-x-0"}`}
            />
          </button>
          <button
            type="button"
            onClick={() => setIsAnnual(true)}
            className={`text-sm font-semibold transition-colors ${isAnnual ? "text-leaf-ink" : "text-leaf-faint"}`}
          >
            Annual
          </button>
          <span className="rounded-md bg-emerald/15 px-2 py-0.5 text-[10px] font-bold uppercase tracking-wide text-emerald-dark dark:text-emerald border border-emerald/30">
            Save 20%
          </span>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-5 sm:gap-6 items-stretch">
          {/* Free */}
          <div
            data-reveal
            data-spring-hover
            className="flex flex-col justify-between rounded-2xl border border-[var(--border-subtle)] bg-leaf-raised p-6 sm:p-7 shadow-soft"
          >
            <div>
              <div className="flex items-center justify-between mb-2">
                <h3 className="font-display text-lg font-bold text-leaf-ink">Free Starter</h3>
                <span className="text-[10px] uppercase tracking-wide text-leaf-faint border border-[var(--border-subtle)] px-2 py-0.5 rounded-md">
                  Perpetual
                </span>
              </div>
              <p className="text-sm text-leaf-muted mb-6 leading-relaxed">
                Stream 70,000+ public domain classics with standard playback and local bookmarks.
              </p>
              <div className="flex items-baseline gap-1 mb-6 pb-6 border-b border-[var(--border-subtle)]">
                <span className="font-display text-4xl font-bold text-leaf-ink">$0</span>
                <span className="text-xs text-leaf-faint">forever</span>
              </div>
              <ul className="space-y-3 text-sm text-leaf-ink">
                {[
                  "70,000+ public domain audiobooks",
                  "1 custom PDF document import",
                  "1 offline book download",
                  "On-device neural speech synthesis",
                ].map((f) => (
                  <li key={f} className="flex items-center gap-2.5">
                    <Check className="h-4 w-4 text-emerald-dark dark:text-emerald shrink-0" />
                    {f}
                  </li>
                ))}
              </ul>
            </div>
            <a
              href="https://apps.apple.com/app/audioby/id6807599877"
              target="_blank"
              rel="noreferrer"
              className="mt-8 flex w-full items-center justify-center rounded-xl border border-[var(--border-subtle)] bg-leaf-surface py-3 text-sm font-bold text-leaf-ink hover:border-emerald/40 transition-colors"
            >
              Get Free on App Store
            </a>
          </div>

          {/* Plus */}
          <div
            data-reveal
            data-spring-hover
            className="flex flex-col justify-between rounded-2xl border border-[var(--border-subtle)] bg-leaf-raised p-6 sm:p-7 shadow-soft"
          >
            <div>
              <div className="flex items-center justify-between mb-2">
                <h3 className="font-display text-lg font-bold text-leaf-ink">Plus</h3>
                <span className="text-[10px] uppercase tracking-wide text-emerald-dark dark:text-emerald border border-emerald/30 bg-emerald/10 px-2 py-0.5 rounded-md font-bold">
                  Power Reader
                </span>
              </div>
              <p className="text-sm text-leaf-muted mb-6 leading-relaxed">
                For researchers and students who import continuously and need limitless offline storage.
              </p>
              <div className="mb-6 pb-6 border-b border-[var(--border-subtle)] min-h-[74px]">
                <span className="font-display text-4xl font-bold text-leaf-ink">{plusPrice}</span>
                <p className="text-xs text-leaf-faint mt-1">{plusPeriod}</p>
              </div>
              <ul className="space-y-3 text-sm text-leaf-ink">
                {[
                  "Unlimited PDF & document imports",
                  "Unlimited offline book downloads",
                  "On-device speech engine",
                  "Universal Web & iOS entitlement sync",
                ].map((f) => (
                  <li key={f} className="flex items-center gap-2.5 font-medium">
                    <Check className="h-4 w-4 text-emerald-dark dark:text-emerald shrink-0" />
                    {f}
                  </li>
                ))}
              </ul>
            </div>
            <button
              type="button"
              onClick={(e) => {
                pulseTap(e.currentTarget);
                onSelectPlan("plus");
              }}
              className="mt-8 flex w-full items-center justify-center gap-1.5 rounded-xl border border-[var(--border-subtle)] bg-leaf-surface py-3 text-sm font-bold text-leaf-ink hover:border-emerald/40 transition-colors"
            >
              Subscribe to Plus
              <ArrowRight className="h-3.5 w-3.5" />
            </button>
          </div>

          {/* Premium */}
          <div
            data-reveal
            data-spring-hover
            className="relative flex flex-col justify-between rounded-2xl border-2 border-emerald-dark dark:border-emerald bg-leaf-raised p-6 sm:p-7 shadow-lift"
          >
            <div className="absolute -top-3 left-6 rounded-full bg-emerald px-3 py-0.5 text-[10px] font-bold uppercase tracking-wider text-emerald-ink">
              Preferred
            </div>
            <div>
              <div className="flex items-center justify-between mb-2">
                <h3 className="font-display text-lg font-bold text-leaf-ink">Premium</h3>
                <span className="text-[10px] uppercase tracking-wide text-emerald-dark dark:text-emerald font-bold">
                  ElevenLabs Studio
                </span>
              </div>
              <p className="text-sm text-leaf-muted mb-6 leading-relaxed">
                Full neural acoustic experience—emotional inflection, natural pauses, and breath modeling.
              </p>
              <div className="mb-6 pb-6 border-b border-[var(--border-subtle)] min-h-[74px]">
                <span className="font-display text-4xl font-bold text-leaf-ink">{premiumPrice}</span>
                <p className="text-xs text-leaf-faint mt-1">{premiumPeriod}</p>
              </div>
              <ul className="space-y-3 text-sm text-leaf-ink">
                {[
                  { t: "150,000 ElevenLabs characters / month", hot: true },
                  { t: "Studio narration: Adam, Rachel & more", hot: false },
                  { t: "Unlimited PDF & document imports", hot: false },
                  { t: "Unlimited offline storage", hot: false },
                  { t: "Priority neural voice bandwidth", hot: false },
                ].map((f) => (
                  <li
                    key={f.t}
                    className={`flex items-center gap-2.5 ${f.hot ? "font-bold text-emerald-dark dark:text-emerald" : "font-medium"}`}
                  >
                    <Check className="h-4 w-4 text-emerald-dark dark:text-emerald shrink-0" />
                    {f.t}
                  </li>
                ))}
              </ul>
            </div>
            <button
              type="button"
              onClick={(e) => {
                pulseTap(e.currentTarget);
                onSelectPlan("premium");
              }}
              className="mt-8 flex w-full items-center justify-center gap-1.5 rounded-xl bg-emerald py-3 text-sm font-bold text-emerald-ink hover:bg-emerald-dark dark:hover:bg-emerald-light transition-colors"
            >
              Subscribe to Premium
              <ArrowRight className="h-3.5 w-3.5" />
            </button>
          </div>
        </div>
      </div>
    </section>
  );
};
