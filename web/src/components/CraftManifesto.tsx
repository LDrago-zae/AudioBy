"use client";

import React from "react";
import { ArrowUpRight } from "lucide-react";
import { useScrollReveal } from "@/lib/anime-motion";

export const CraftManifesto: React.FC = () => {
  const ref = useScrollReveal<HTMLElement>();

  return (
    <section
      ref={ref}
      className="py-16 sm:py-24 border-t border-[var(--border-subtle)] bg-leaf-surface paper-grain"
    >
      <div className="mx-auto max-w-3xl px-4 sm:px-6">
        <h2
          data-reveal
          className="font-display text-2xl sm:text-4xl font-bold tracking-tight text-leaf-ink leading-tight"
        >
          Books are meant to be understood, not abandoned to fatigue.
        </h2>

        <div
          data-reveal
          className="mt-6 sm:mt-8 space-y-4 text-sm sm:text-base text-leaf-muted leading-relaxed max-w-measure"
        >
          <p>
            We love books and research, but staring at displays for ten hours makes another fifty pages of dense PDF in the evening almost impossible.
          </p>
          <p>
            Commercial platforms charge credit fees and lock titles behind DRM. Standard text-to-speech still sounds like a GPS from twenty years ago.
          </p>
          <p className="text-leaf-ink font-semibold">
            AudioBy combines the open public library, a distraction-free offline player, and nuanced ElevenLabs neural voices—so serious ideas travel with you on a walk, in the car, or late at night.
          </p>
        </div>

        <div
          data-reveal
          className="mt-8 pt-6 border-t border-[var(--border-subtle)] flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3"
        >
          <p className="text-xs text-leaf-faint">Engineered natively with Swift and modern web standards.</p>
          <a
            href="https://apps.apple.com/app/audioby/id6807599877"
            target="_blank"
            rel="noreferrer"
            className="inline-flex items-center gap-1.5 text-sm font-semibold text-emerald-dark dark:text-emerald hover:underline"
          >
            View on the App Store
            <ArrowUpRight className="h-3.5 w-3.5" />
          </a>
        </div>
      </div>
    </section>
  );
};
