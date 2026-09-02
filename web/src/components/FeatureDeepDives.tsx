"use client";

import React from "react";
import { motion } from "motion/react";
import { Check } from "lucide-react";

const DEEP_DIVES = [
  {
    number: "01",
    tag: "NEURAL PLAYER",
    title: "A player designed for focus, not advertisements",
    description:
      "AudioBy remembers your exact position across every book and document. With pitch-compensated speed controls up to 2.5x and sleep timers that gently pause at chapter boundaries, your progress never slips overnight.",
    bullets: [
      "Precise chapter hierarchy indexing",
      "Pitch-compensated variable speed (0.75x – 2.5x)",
      "Sleep timer: by minutes or at end-of-chapter",
      "Instant bookmarking and excerpt storage",
    ],
    metric: "0.75x – 2.5x",
    metricLabel: "Pitch-preserved speed",
  },
  {
    number: "02",
    tag: "DOCUMENT ENGINE",
    title: "Drop any PDF. Listen within three seconds.",
    description:
      "Academic papers and long-form documents are notoriously difficult for standard readers. AudioBy's layout-aware engine extracts the true reading flow, stripping headers, footnotes, and formatting noise so the speech flows like a real lecture.",
    bullets: [
      "Strips repeated page headers and footers",
      "Cleans up two-column research paper layouts",
      "Supports textbook chapters and lecture notes",
      "Local on-device text extraction",
    ],
    metric: "3 sec",
    metricLabel: "From import to spoken audio",
  },
  {
    number: "03",
    tag: "STUDIO VOICES",
    title: "ElevenLabs AI: human emotion, pauses, and breath",
    description:
      "Standard text-to-speech tools tire your ears because they miss human vocal micro-rhythms. Premium tier integrates ElevenLabs neural synthesis to deliver novel-grade narration that brings fiction, drama, and history to life.",
    bullets: [
      "Realistic inflection for character dialogue",
      "Natural conversational breathing pauses",
      "Cached neural narration for offline recall",
      "Multiple studio voices including Adam and Rachel",
    ],
    metric: "100%",
    metricLabel: "Studio vocal fidelity",
  },
  {
    number: "04",
    tag: "PRIVACY & LOCAL CACHING",
    title: "Nobody should have to stream what they already downloaded",
    description:
      "AudioBy stores entire books and converted documents directly in your device's filesystem. Everything works on airplanes, underground transit, and off-grid locations with zero cellular connection.",
    bullets: [
      "100% on-device offline cache",
      "Zero telemetry or listening tracking",
      "Free public catalog requires no account",
      "Full export and deletion anytime",
    ],
    metric: "0 bytes",
    metricLabel: "Leaked to data brokers",
  },
];

export const FeatureDeepDives: React.FC = () => {
  return (
    <section id="engine" className="py-14 sm:py-20 md:py-24 border-t border-black/[0.08] dark:border-white/[0.08] bg-[#F9FAF9] dark:bg-[#0C100E] relative transition-colors duration-200">
      <div className="mx-auto max-w-6xl px-3.5 sm:px-6">
        <div className="space-y-12 sm:space-y-20">
          {DEEP_DIVES.map((item, idx) => (
            <motion.div
              key={idx}
              initial={{ opacity: 0, y: 32 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true, margin: "-60px" }}
              transition={{ duration: 0.6, ease: [0.16, 1, 0.3, 1] }}
              className={`flex flex-col lg:flex-row gap-6 sm:gap-10 lg:gap-14 items-center ${
                idx % 2 === 1 ? "lg:flex-row-reverse" : ""
              }`}
            >
              {/* Text column */}
              <div className="w-full lg:w-1/2">
                <div className="flex items-center gap-2 mb-2 sm:mb-3">
                  <span className="font-mono text-xs font-bold text-[#0F9B51] dark:text-emerald">
                    {item.number}
                  </span>
                  <span className="text-black/20 dark:text-white/20">/</span>
                  <span className="font-mono text-[10px] tracking-eyebrow uppercase text-zinc-500 dark:text-ink-muted">
                    {item.tag}
                  </span>
                </div>

                <h3 className="text-xl sm:text-2xl md:text-3xl font-bold tracking-tight text-zinc-900 dark:text-white mb-3 sm:mb-4 leading-snug">
                  {item.title}
                </h3>

                <p className="text-xs sm:text-base text-zinc-600 dark:text-ink-secondary leading-relaxed mb-4 sm:mb-6">
                  {item.description}
                </p>

                <div className="space-y-2 sm:space-y-2.5">
                  {item.bullets.map((b, bIdx) => (
                    <div key={bIdx} className="flex items-center gap-2.5 text-xs text-zinc-800 dark:text-ink-primary">
                      <span className="flex h-4 w-4 shrink-0 items-center justify-center rounded-full bg-emerald/15 text-[#0F9B51] dark:text-emerald">
                        <Check className="h-2.5 w-2.5" />
                      </span>
                      <span>{b}</span>
                    </div>
                  ))}
                </div>
              </div>

              {/* Stat / Visual Card column with interactive hover lift */}
              <motion.div
                whileHover={{ y: -6, transition: { duration: 0.2 } }}
                className="w-full lg:w-1/2"
              >
                <div className="rounded-2xl border border-black/[0.08] dark:border-white/10 bg-white dark:bg-[#121714] p-5 sm:p-8 shadow-lg dark:shadow-elevated hover:border-[#0F9B51]/30 dark:hover:border-emerald/30 transition-colors">
                  <div className="flex items-center justify-between pb-4 sm:pb-6 border-b border-black/[0.06] dark:border-white/[0.06] mb-4 sm:mb-6">
                    <span className="font-mono text-[10px] sm:text-xs text-zinc-500 dark:text-ink-muted uppercase tracking-wider">
                      Engine Spec {item.number}
                    </span>
                    <span className="h-2 w-2 rounded-full bg-emerald animate-pulse" />
                  </div>

                  <div className="py-3 sm:py-6">
                    <div className="text-3xl sm:text-4xl md:text-5xl font-mono font-bold text-zinc-900 dark:text-white mb-1.5 sm:mb-2">
                      {item.metric}
                    </div>
                    <div className="text-[11px] sm:text-xs font-mono uppercase tracking-wider text-[#0F9B51] dark:text-emerald">
                      {item.metricLabel}
                    </div>
                  </div>

                  <div className="pt-4 sm:pt-6 border-t border-black/[0.06] dark:border-white/[0.06] text-[10px] sm:text-xs text-zinc-500 dark:text-ink-secondary font-mono flex flex-col xs:flex-row items-start xs:items-center justify-between gap-1">
                    <span>Target: Zero Cognitive Friction</span>
                    <span className="text-[#0F9B51] dark:text-emerald">Validated</span>
                  </div>
                </div>
              </motion.div>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  );
};
