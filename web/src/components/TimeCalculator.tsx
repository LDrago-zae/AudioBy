"use client";

import React, { useState } from "react";
import { motion } from "motion/react";
import { Clock, BookOpen, TrendingUp } from "lucide-react";

export const TimeCalculator: React.FC = () => {
  const [pagesPerWeek, setPagesPerWeek] = useState<number>(100);

  const hoursPerWeek = ((pagesPerWeek * 1.4) / 60).toFixed(1);
  const hoursPerYear = Math.round(Number(hoursPerWeek) * 52);
  const booksPerYear = Math.max(1, Math.round((pagesPerWeek * 52) / 250));
  const audibleCreditCost = booksPerYear * 15;
  const audioByAnnualCost = 59;
  const savings = Math.max(0, audibleCreditCost - audioByAnnualCost);

  return (
    <section id="calculator" className="py-14 sm:py-20 md:py-24 border-t border-black/[0.08] dark:border-white/[0.08] bg-[#F9FAF9] dark:bg-[#0A0D0B] relative transition-colors duration-200">
      <div className="mx-auto max-w-5xl px-3.5 sm:px-6">
        {/* Header */}
        <div className="text-center max-w-2xl mx-auto mb-8 sm:mb-14">
          <motion.div
            initial={{ opacity: 0, y: -10 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            className="inline-flex items-center gap-2 mb-3 text-[10px] font-mono tracking-eyebrow uppercase text-[#0F9B51] dark:text-emerald"
          >
            <span className="h-1.5 w-1.5 rounded-full bg-emerald animate-pulse" />
            <span>Interactive Reading Calculator</span>
          </motion.div>

          <motion.h2
            initial={{ opacity: 0, y: 14 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ delay: 0.1 }}
            className="text-2xl sm:text-4xl md:text-5xl font-bold tracking-tight text-zinc-900 dark:text-white"
          >
            Calculate Your Hours Unlocked
          </motion.h2>

          <motion.p
            initial={{ opacity: 0, y: 14 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ delay: 0.2 }}
            className="mt-2.5 sm:mt-3 text-xs sm:text-sm text-zinc-600 dark:text-ink-secondary"
          >
            Drag the slider to your weekly reading load and see how much screen fatigue turns into audio time.
          </motion.p>
        </div>

        {/* Calculator Card */}
        <motion.div
          initial={{ opacity: 0, y: 24 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6, delay: 0.2 }}
          className="rounded-2xl border border-black/[0.08] dark:border-white/10 bg-white dark:bg-[#121714] p-4 sm:p-8 md:p-10 shadow-lg dark:shadow-elevated transition-colors"
        >
          {/* Slider input */}
          <div className="pb-6 sm:pb-8 border-b border-black/[0.06] dark:border-white/[0.06]">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2.5 mb-4">
              <label className="text-xs sm:text-sm font-semibold text-zinc-900 dark:text-white">
                How many pages of PDFs, articles, or books do you read each week?
              </label>
              <motion.div
                key={pagesPerWeek}
                initial={{ scale: 1.15 }}
                animate={{ scale: 1 }}
                transition={{ type: "spring", stiffness: 400, damping: 20 }}
                className="self-start sm:self-auto rounded-lg bg-[#EAEFEA] dark:bg-[#1B231E] border border-black/[0.08] dark:border-white/10 px-3 py-1 font-mono text-xs sm:text-sm font-bold text-[#0F9B51] dark:text-emerald shadow-sm"
              >
                {pagesPerWeek} pages / week
              </motion.div>
            </div>

            <input
              type="range"
              min={20}
              max={400}
              step={10}
              value={pagesPerWeek}
              onChange={(e) => setPagesPerWeek(Number(e.target.value))}
              className="w-full h-2.5 bg-[#E2E8E2] dark:bg-[#1B231E] rounded-lg appearance-none cursor-pointer accent-emerald"
            />

            <div className="flex justify-between text-[10px] sm:text-[11px] font-mono text-zinc-500 dark:text-ink-muted mt-2">
              <span>20p (Casual)</span>
              <span className="hidden xs:inline sm:inline">150p (Student)</span>
              <span>400p (Intensive)</span>
            </div>
          </div>

          {/* Results Grid with interactive hover springs */}
          <div className="mt-6 sm:mt-8 grid grid-cols-1 sm:grid-cols-3 gap-3.5 sm:gap-6">
            <motion.div
              whileHover={{ y: -4 }}
              transition={{ duration: 0.2 }}
              className="rounded-xl border border-black/[0.06] dark:border-white/5 bg-[#F6FAF6] dark:bg-[#161D19] p-4 sm:p-5 shadow-sm"
            >
              <div className="flex items-center gap-2 text-zinc-500 dark:text-ink-muted text-xs font-mono mb-2">
                <Clock className="h-3.5 w-3.5 text-[#0F9B51] dark:text-emerald" />
                <span>Audio Time Gained</span>
              </div>
              <motion.div
                key={hoursPerWeek}
                initial={{ opacity: 0.5, y: -4 }}
                animate={{ opacity: 1, y: 0 }}
                className="text-xl sm:text-2xl lg:text-3xl font-bold font-mono text-zinc-900 dark:text-white"
              >
                {hoursPerWeek} hrs <span className="text-xs text-zinc-500 dark:text-ink-muted font-normal">/ week</span>
              </motion.div>
              <p className="mt-2 text-[10px] sm:text-[11px] text-zinc-600 dark:text-ink-secondary leading-relaxed">
                Turn {hoursPerYear} hours per year of screen fatigue into active listening during walks, cooking, or commutes.
              </p>
            </motion.div>

            <motion.div
              whileHover={{ y: -4 }}
              transition={{ duration: 0.2 }}
              className="rounded-xl border border-black/[0.06] dark:border-white/5 bg-[#F6FAF6] dark:bg-[#161D19] p-4 sm:p-5 shadow-sm"
            >
              <div className="flex items-center gap-2 text-zinc-500 dark:text-ink-muted text-xs font-mono mb-2">
                <BookOpen className="h-3.5 w-3.5 text-[#0F9B51] dark:text-emerald" />
                <span>Books Completed</span>
              </div>
              <motion.div
                key={booksPerYear}
                initial={{ opacity: 0.5, y: -4 }}
                animate={{ opacity: 1, y: 0 }}
                className="text-xl sm:text-2xl lg:text-3xl font-bold font-mono text-zinc-900 dark:text-white"
              >
                ~{booksPerYear} titles <span className="text-xs text-zinc-500 dark:text-ink-muted font-normal">/ year</span>
              </motion.div>
              <p className="mt-2 text-[10px] sm:text-[11px] text-zinc-600 dark:text-ink-secondary leading-relaxed">
                Equivalent to finishing a standard-length book or comprehensive research paper every {Math.max(1, Math.round(52 / booksPerYear))} weeks.
              </p>
            </motion.div>

            <motion.div
              whileHover={{ y: -4 }}
              transition={{ duration: 0.2 }}
              className="rounded-xl border border-black/[0.06] dark:border-white/5 bg-[#F6FAF6] dark:bg-[#161D19] p-4 sm:p-5 shadow-sm"
            >
              <div className="flex items-center gap-2 text-zinc-500 dark:text-ink-muted text-xs font-mono mb-2">
                <TrendingUp className="h-3.5 w-3.5 text-[#0F9B51] dark:text-emerald" />
                <span>Savings vs Audible</span>
              </div>
              <motion.div
                key={savings}
                initial={{ opacity: 0.5, y: -4 }}
                animate={{ opacity: 1, y: 0 }}
                className="text-xl sm:text-2xl lg:text-3xl font-bold font-mono text-[#0F9B51] dark:text-emerald"
              >
                ${savings} <span className="text-xs text-zinc-500 dark:text-ink-muted font-normal">/ year saved</span>
              </motion.div>
              <p className="mt-2 text-[10px] sm:text-[11px] text-zinc-600 dark:text-ink-secondary leading-relaxed">
                Audible credits cost $15/book (${audibleCreditCost}/yr). AudioBy Plus provides unlimited access for $4.99/mo ($59/yr).
              </p>
            </motion.div>
          </div>
        </motion.div>
      </div>
    </section>
  );
};
