"use client";

import React from "react";
import { motion } from "motion/react";

const PROBLEMS = [
  {
    code: "00:10:00 · CADENCE FATIGUE",
    title: "Robotic synthesizers cause auditory exhaustion",
    detail:
      "Conventional text-to-speech tools read in a flat, machine cadence with robotic inflexibility. After just ten minutes, your auditory cortex works overtime to parse sentences, turning long-form listening into a mental chore.",
    resolution: "Resolved: Natural cadence acoustic synthesis",
  },
  {
    code: "DOC-PARSE · SYNTAX CLUTTER",
    title: "PDF formatting breaks standard readers",
    detail:
      "Academic papers, articles, and scanned books are full of header clutter, citations, and footnotes. Standard readers read every page number and URL aloud, destroying your comprehension.",
    resolution: "Resolved: Intelligent layout & footnote filtering",
  },
  {
    code: "OFF-GRID · DRM FAILURE",
    title: "Streaming apps lock you out when offline",
    detail:
      "Most commercial audio platforms require continuous connectivity or proprietary DRM wrappers. The moment you step into the subway or onto a flight, playback stutters and halts.",
    resolution: "Resolved: 100% offline local SQLite audio cache",
  },
];

export const ProblemSection: React.FC = () => {
  return (
    <section id="problem" className="py-14 sm:py-20 md:py-24 border-t border-black/[0.08] dark:border-white/[0.08] bg-[#F8FAF8] dark:bg-[#08090B] relative transition-colors duration-200">
      <div className="mx-auto max-w-6xl px-3.5 sm:px-6">
        {/* Section Header */}
        <div className="max-w-3xl mb-8 sm:mb-14">
          <motion.div
            initial={{ opacity: 0, y: -10 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            className="flex items-center gap-2 mb-3 text-[11px] font-mono tracking-wider uppercase text-zinc-500 dark:text-zinc-400"
          >
            <span className="font-bold text-[#059669] dark:text-[#10B981]">[ 02 ]</span>
            <span className="font-semibold text-zinc-700 dark:text-zinc-300">WHY CONVENTIONAL AUDIO READERS FAIL</span>
          </motion.div>

          <motion.h2
            initial={{ opacity: 0, y: 14 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ delay: 0.1 }}
            className="text-2xl sm:text-4xl md:text-5xl font-bold tracking-tight text-zinc-950 dark:text-white leading-tight"
          >
            You didn&apos;t lose focus.
            <br />
            <span className="text-zinc-500 dark:text-zinc-400 font-normal block sm:inline">
              The tools were designed for screens, not ears.
            </span>
          </motion.h2>
        </div>

        {/* 3 Split Cards */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 sm:gap-6">
          {PROBLEMS.map((item, idx) => (
            <motion.div
              key={idx}
              initial={{ opacity: 0, y: 24 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.5, delay: idx * 0.12 }}
              whileHover={{ y: -4, transition: { duration: 0.2 } }}
              className="rounded-2xl border border-black/[0.08] dark:border-white/[0.08] bg-white dark:bg-[#0E1015] p-5 sm:p-7 flex flex-col justify-between hover:border-black/20 dark:hover:border-white/[0.18] transition-colors shadow-sm dark:shadow-tactile"
            >
              <div>
                <span className="font-mono text-[10px] sm:text-[11px] text-[#059669] dark:text-[#10B981] border border-black/[0.08] dark:border-white/[0.10] bg-black/[0.02] dark:bg-[#14171E] px-2.5 py-1 rounded-md inline-block mb-4 sm:mb-5 font-medium">
                  {item.code}
                </span>

                <h3 className="text-base sm:text-lg font-bold text-zinc-950 dark:text-white mb-2.5 sm:mb-3 leading-snug">
                  {item.title}
                </h3>

                <p className="text-xs sm:text-sm text-zinc-600 dark:text-zinc-400 leading-relaxed">
                  {item.detail}
                </p>
              </div>

              <div className="mt-6 sm:mt-8 pt-3 sm:pt-4 border-t border-black/[0.04] dark:border-white/[0.06] text-[10px] sm:text-[11px] font-mono text-[#059669] dark:text-[#10B981]">
                {item.resolution}
              </div>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  );
};
