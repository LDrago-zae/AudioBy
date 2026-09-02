"use client";

import React from "react";
import { motion } from "motion/react";

const PROBLEMS = [
  {
    time: "10 mins in",
    title: "Robotic synthesizers cause auditory fatigue",
    detail:
      "Conventional text-to-speech tools read in a flat, machine cadence with robotic inflexibility. After just ten minutes, your auditory cortex works overtime to parse sentences, turning long-form listening into a mental chore.",
  },
  {
    time: "Every paper",
    title: "PDF formatting breaks standard readers",
    detail:
      "Academic papers, articles, and scanned books are full of header clutter, citations, and footnotes. Standard readers read every page number and URL aloud, destroying your comprehension.",
  },
  {
    time: "Offline travel",
    title: "Streaming apps lock you out when reception drops",
    detail:
      "Most commercial audio platforms require continuous connectivity or proprietary DRM wrappers. The moment you step into the subway or onto a flight, playback stutters and halts.",
  },
];

export const ProblemSection: React.FC = () => {
  return (
    <section id="problem" className="py-14 sm:py-20 md:py-24 border-t border-black/[0.08] dark:border-white/[0.08] bg-[#F9FAF9] dark:bg-[#0C100E] relative transition-colors duration-200">
      <div className="mx-auto max-w-6xl px-3.5 sm:px-6">
        {/* Section Header */}
        <div className="max-w-3xl mb-8 sm:mb-14">
          <motion.div
            initial={{ opacity: 0, y: -10 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            className="inline-flex items-center gap-2 mb-3 text-[10px] font-mono tracking-eyebrow uppercase text-[#0F9B51] dark:text-emerald"
          >
            <span className="h-1.5 w-1.5 rounded-full bg-emerald animate-pulse" />
            <span>Why Reading Fails on Screens</span>
          </motion.div>

          <motion.h2
            initial={{ opacity: 0, y: 14 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ delay: 0.1 }}
            className="text-2xl sm:text-4xl md:text-5xl font-bold tracking-tight text-zinc-900 dark:text-white leading-tight"
          >
            You didn&apos;t lose focus.
            <br />
            <span className="text-zinc-600 dark:text-ink-secondary font-normal block sm:inline">
              The tools were designed for screens, not ears.
            </span>
          </motion.h2>
        </div>

        {/* 3 Split Cards with staggered reveal and hover physics */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 sm:gap-6">
          {PROBLEMS.map((item, idx) => (
            <motion.div
              key={idx}
              initial={{ opacity: 0, y: 24 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.5, delay: idx * 0.12 }}
              whileHover={{ y: -6, transition: { duration: 0.2 } }}
              className="rounded-2xl border border-black/[0.08] dark:border-white/10 bg-white dark:bg-[#121714] p-5 sm:p-7 flex flex-col justify-between hover:border-[#0F9B51]/40 dark:hover:border-emerald/40 transition-colors shadow-sm dark:shadow-card"
            >
              <div>
                <span className="font-mono text-xs text-[#0F9B51] dark:text-emerald border border-emerald/30 dark:border-emerald/20 bg-emerald/10 dark:bg-emerald/5 px-2.5 py-1 rounded-md inline-block mb-4 sm:mb-5">
                  {item.time}
                </span>

                <h3 className="text-base sm:text-lg font-bold text-zinc-900 dark:text-white mb-2.5 sm:mb-3 leading-snug">
                  {item.title}
                </h3>

                <p className="text-xs sm:text-sm text-zinc-600 dark:text-ink-secondary leading-relaxed">
                  {item.detail}
                </p>
              </div>

              <div className="mt-6 sm:mt-8 pt-3 sm:pt-4 border-t border-black/[0.04] dark:border-white/[0.04] text-[10px] sm:text-[11px] font-mono text-zinc-400 dark:text-ink-muted">
                AudioBy eliminates this by design.
              </div>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  );
};
