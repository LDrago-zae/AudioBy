"use client";

import React from "react";
import { ArrowUpRight } from "lucide-react";

export const CraftManifesto: React.FC = () => {
  return (
    <section className="py-12 sm:py-20 border-t border-black/[0.08] dark:border-white/[0.08] bg-[#F1F5F2] dark:bg-[#0A0D0B] transition-colors duration-200">
      <div className="mx-auto max-w-4xl px-3.5 sm:px-6">
        <div className="rounded-2xl border border-black/[0.08] dark:border-white/10 bg-white dark:bg-[#121714] p-5 sm:p-10 md:p-12 shadow-lg dark:shadow-elevated transition-colors">
          <div className="flex items-center gap-2 mb-3 sm:mb-4 text-[10px] font-mono tracking-eyebrow uppercase text-[#0F9B51] dark:text-emerald">
            <span className="h-1.5 w-1.5 rounded-full bg-emerald" />
            <span>Built by Readers, For Readers</span>
          </div>

          <h3 className="text-xl sm:text-2xl md:text-3xl font-bold tracking-tight text-zinc-900 dark:text-white mb-4 sm:mb-6">
            Why we built AudioBy
          </h3>

          <div className="space-y-3.5 sm:space-y-4 text-xs sm:text-sm md:text-base text-zinc-600 dark:text-ink-secondary leading-relaxed">
            <p>
              We love books and research, but staring at screens for ten hours a day makes reading another 50 pages of dense PDF text in the evening almost impossible.
            </p>
            <p>
              Traditional audiobook stores charge $15 every month for a single credit and lock you inside their closed app. Meanwhile, existing text-to-speech tools sounded like 1990s GPS voice directions that caused mental fatigue within minutes.
            </p>
            <p className="text-zinc-900 dark:text-white font-medium">
              AudioBy exists to fix this. We combined the entire open public library, a distraction-free offline player, and modern ElevenLabs neural voices so you can absorb serious ideas anywhere—on a morning walk, behind the wheel, or relaxing at night.
            </p>
          </div>

          <div className="mt-6 sm:mt-8 pt-5 sm:pt-6 border-t border-black/[0.06] dark:border-white/[0.06] flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3">
            <div className="text-[11px] sm:text-xs text-zinc-500 dark:text-ink-muted">
              Built natively with Swift and modern Web standards.
            </div>

            <a
              href="https://apps.apple.com/app/audioby/id6807599877"
              target="_blank"
              rel="noreferrer"
              className="inline-flex items-center gap-1.5 text-xs font-mono font-semibold text-[#0F9B51] dark:text-emerald hover:underline"
            >
              <span>View on iOS App Store</span>
              <ArrowUpRight className="h-3.5 w-3.5" />
            </a>
          </div>
        </div>
      </div>
    </section>
  );
};
