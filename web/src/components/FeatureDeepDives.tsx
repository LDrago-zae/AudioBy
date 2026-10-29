"use client";

import React from "react";
import { Check } from "lucide-react";
import { useScrollReveal } from "@/lib/anime-motion";

const DEEP_DIVES = [
  {
    tag: "Neural player",
    title: "A player designed for focus, not advertisements",
    description:
      "AudioBy remembers your exact position across every book and document. Pitch-compensated speed up to 2.5x and sleep timers that pause at chapter boundaries keep progress intact overnight.",
    bullets: [
      "Precise chapter hierarchy indexing",
      "Pitch-compensated variable speed (0.75x – 2.5x)",
      "Sleep timer: by minutes or end-of-chapter",
      "Instant bookmarking and excerpt storage",
    ],
    metric: "0.75x – 2.5x",
    metricLabel: "Pitch-preserved speed",
  },
  {
    tag: "Document engine",
    title: "Drop any PDF. Listen within three seconds.",
    description:
      "Layout-aware extraction finds the true reading flow, stripping headers, footnotes, and formatting noise so speech flows like a real lecture.",
    bullets: [
      "Strips repeated page headers and footers",
      "Cleans two-column research layouts",
      "Supports textbook chapters and lecture notes",
      "Local on-device text extraction",
    ],
    metric: "3 sec",
    metricLabel: "PDF to spoken audio",
  },
  {
    tag: "Studio voices",
    title: "ElevenLabs: emotion, pauses, and breath",
    description:
      "Premium integrates ElevenLabs neural synthesis for novel-grade narration—inflection, breathing pauses, and emotional phrasing that lasts for hours.",
    bullets: [
      "Realistic inflection for dialogue",
      "Natural conversational breathing",
      "Cached neural narration for offline",
      "Studio voices including Adam and Rachel",
    ],
    metric: "Studio",
    metricLabel: "Vocal fidelity",
  },
  {
    tag: "Privacy & cache",
    title: "Nobody should stream what they already downloaded",
    description:
      "Entire books and converted documents live on your device. Airplanes, underground transit, and off-grid locations work with zero cellular connection.",
    bullets: [
      "On-device offline SQLite cache",
      "Zero telemetry or listening tracking",
      "Free public catalog needs no account",
      "Full export and deletion anytime",
    ],
    metric: "0 bytes",
    metricLabel: "Sent to ad trackers",
  },
];

export const FeatureDeepDives: React.FC = () => {
  const ref = useScrollReveal<HTMLElement>();

  return (
    <section
      id="engine"
      ref={ref}
      className="py-16 sm:py-24 border-t border-[var(--border-subtle)] bg-[var(--background)]"
    >
      <div className="mx-auto max-w-6xl px-4 sm:px-6 space-y-16 sm:space-y-24">
        {DEEP_DIVES.map((item) => (
          <article
            key={item.tag}
            data-reveal
            className="grid md:grid-cols-[1.4fr_0.8fr] gap-8 md:gap-12 items-start"
          >
            <div>
              <p className="text-sm font-semibold text-emerald-dark dark:text-emerald mb-3">
                {item.tag}
              </p>
              <h2 className="font-display text-2xl sm:text-4xl font-bold tracking-tight text-leaf-ink leading-tight">
                {item.title}
              </h2>
              <p className="mt-4 max-w-measure text-sm sm:text-base text-leaf-muted leading-relaxed">
                {item.description}
              </p>
              <ul className="mt-6 space-y-2.5">
                {item.bullets.map((b) => (
                  <li key={b} className="flex items-start gap-2.5 text-sm text-leaf-ink">
                    <Check className="h-4 w-4 text-emerald-dark dark:text-emerald shrink-0 mt-0.5" />
                    <span>{b}</span>
                  </li>
                ))}
              </ul>
            </div>
            <div className="rounded-2xl border border-[var(--border-subtle)] bg-leaf-raised p-6 sm:p-8 shadow-soft">
              <p className="font-display text-3xl sm:text-4xl font-bold tracking-tight text-leaf-ink">
                {item.metric}
              </p>
              <p className="mt-2 text-sm text-leaf-muted">{item.metricLabel}</p>
            </div>
          </article>
        ))}
      </div>
    </section>
  );
};
