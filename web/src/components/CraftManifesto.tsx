"use client";

import React from "react";
import { ArrowUpRight } from "lucide-react";

export const CraftManifesto: React.FC = () => {
  return (
    <section className="py-12 sm:py-20 border-t border-black/[0.08] dark:border-white/[0.08] bg-zinc-100/60 dark:bg-[#0B0D11] transition-colors duration-200">
      <div className="mx-auto max-w-4xl px-3.5 sm:px-6">
        <div className="rounded-2xl border border-black/[0.08] dark:border-white/[0.08] bg-white dark:bg-[#0E1015] p-5 sm:p-10 md:p-12 shadow-md dark:shadow-console transition-colors">
          <div className="flex items-center gap-2 mb-3 sm:mb-4 text-[11px] font-mono tracking-wider uppercase text-zinc-500 dark:text-zinc-400">
            <span className="font-bold text-[#059669] dark:text-[#10B981]">[ 07 ]</span>
            <span className="font-semibold text-zinc-700 dark:text-zinc-300">WHY WE BUILT AUDIOBY</span>
          </div>

          <h3 className="text-xl sm:text-2xl md:text-3xl font-bold tracking-tight text-zinc-950 dark:text-white mb-4 sm:mb-6">
            Books are meant to be understood, not abandoned to fatigue.
          </h3>

          <div className="space-y-3.5 sm:space-y-4 text-xs sm:text-sm md:text-base text-zinc-600 dark:text-zinc-400 leading-relaxed">
            <p>
              We love books and research, but staring at displays for ten hours during the workday makes reading another 50 pages of dense technical PDF text in the evening almost impossible.
            </p>
            <p>
              Commercial audiobook conglomerates charge exorbitant monthly credit fees and lock titles into proprietary, DRM-choked apps. Meanwhile, standard text-to-speech engines sounded like robotic GPS navigation units from twenty years ago, inducing auditory strain in under ten minutes.
            </p>
            <p className="text-zinc-900 dark:text-zinc-100 font-medium">
              AudioBy combines the open public library, a distraction-free offline player, and nuanced ElevenLabs neural voices so you can absorb serious ideas anywhere—on a long walk, behind the wheel, or in the stillness of night.
            </p>
          </div>

          <div className="mt-6 sm:mt-8 pt-5 sm:pt-6 border-t border-black/[0.06] dark:border-white/[0.06] flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3">
            <div className="text-[11px] sm:text-xs text-zinc-500 dark:text-zinc-500 font-mono">
              Engineered natively with Swift and modern Web standards.
            </div>

            <a
              href="https://apps.apple.com/app/audioby/id6807599877"
              target="_blank"
              rel="noreferrer"
              className="inline-flex items-center gap-1.5 text-xs font-mono font-semibold text-[#059669] dark:text-[#10B981] hover:underline"
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
