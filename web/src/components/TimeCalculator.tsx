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
    <section id="calculator" className="py-14 sm:py-20 md:py-24 border-t border-black/[0.08] dark:border-white/[0.08] bg-[#F8FAF8] dark:bg-[#08090B] relative transition-colors duration-200">
      <div className="mx-auto max-w-5xl px-3.5 sm:px-6">
        {/* Header */}
        <div className="text-center max-w-2xl mx-auto mb-8 sm:mb-14">
          <motion.div
            initial={{ opacity: 0, y: -10 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            className="flex items-center justify-center gap-2 mb-3 text-[11px] font-mono tracking-wider uppercase text-zinc-500 dark:text-zinc-400"
          >
            <span className="font-bold text-[#059669] dark:text-[#10B981]">[ 04 ]</span>
            <span className="font-semibold text-zinc-700 dark:text-zinc-300">READING CONVERSION ARITHMETIC</span>
          </motion.div>

          <motion.h2
            initial={{ opacity: 0, y: 14 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ delay: 0.1 }}
            className="text-2xl sm:text-4xl md:text-5xl font-bold tracking-tight text-zinc-950 dark:text-white"
          >
            Calculate hours unlocked.
          </motion.h2>

          <motion.p
            initial={{ opacity: 0, y: 14 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ delay: 0.2 }}
            className="mt-2.5 sm:mt-3 text-xs sm:text-base text-zinc-600 dark:text-zinc-400"
          >
            See how much screen-locked reading turns into flexible acoustic audio during walks, commutes, and rest.
          </motion.p>
        </div>

        {/* Calculator Card */}
        <motion.div
          initial={{ opacity: 0, y: 24 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6, delay: 0.2 }}
          className="rounded-2xl border border-black/[0.08] dark:border-white/[0.08] bg-white dark:bg-[#0E1015] p-5 sm:p-8 md:p-10 shadow-md dark:shadow-console transition-colors"
        >
          {/* Slider input */}
          <div className="pb-6 sm:pb-8 border-b border-black/[0.06] dark:border-white/[0.06]">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2.5 mb-4">
              <label className="text-xs sm:text-sm font-semibold text-zinc-950 dark:text-white">
                Weekly document & book reading load:
              </label>
              <motion.div
                key={pagesPerWeek}
                initial={{ scale: 1.1 }}
                animate={{ scale: 1 }}
                transition={{ type: "spring", stiffness: 400, damping: 20 }}
                className="self-start sm:self-auto rounded-lg bg-zinc-100 dark:bg-[#161922] border border-black/[0.08] dark:border-white/[0.1] px-3 py-1 font-mono text-xs sm:text-sm font-bold text-[#059669] dark:text-[#10B981] shadow-sm"
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
              className="w-full h-2.5 bg-zinc-200 dark:bg-[#161922] rounded-lg appearance-none cursor-pointer accent-[#10B981]"
            />

            <div className="flex justify-between text-[10px] sm:text-[11px] font-mono text-zinc-500 dark:text-zinc-500 mt-2.5">
              <span>20p (Casual)</span>
              <span className="hidden xs:inline sm:inline">150p (Student / Researcher)</span>
              <span>400p (Academic / Executive)</span>
            </div>
          </div>

          {/* Results Grid */}
          <div className="mt-6 sm:mt-8 grid grid-cols-1 sm:grid-cols-3 gap-3.5 sm:gap-6">
            <motion.div
              whileHover={{ y: -3 }}
              transition={{ duration: 0.2 }}
              className="rounded-xl border border-black/[0.06] dark:border-white/[0.06] bg-zinc-50 dark:bg-[#12151B] p-4 sm:p-5 shadow-sm"
            >
              <div className="flex items-center gap-2 text-zinc-500 dark:text-zinc-400 text-xs font-mono mb-2">
                <Clock className="h-3.5 w-3.5 text-[#059669] dark:text-[#10B981]" />
                <span>Audio Time Recovered</span>
              </div>
              <motion.div
                key={hoursPerWeek}
                initial={{ opacity: 0.5, y: -4 }}
                animate={{ opacity: 1, y: 0 }}
                className="text-xl sm:text-2xl lg:text-3xl font-bold font-mono text-zinc-950 dark:text-white"
              >
                {hoursPerWeek} hrs <span className="text-xs text-zinc-500 dark:text-zinc-500 font-normal">/ wk</span>
              </motion.div>
              <p className="mt-2 text-[11px] text-zinc-600 dark:text-zinc-400 leading-relaxed">
                Turn {hoursPerYear} hours per year of screen fatigue into active listening while walking, cooking, or commuting.
              </p>
            </motion.div>

            <motion.div
              whileHover={{ y: -3 }}
              transition={{ duration: 0.2 }}
              className="rounded-xl border border-black/[0.06] dark:border-white/[0.06] bg-zinc-50 dark:bg-[#12151B] p-4 sm:p-5 shadow-sm"
            >
              <div className="flex items-center gap-2 text-zinc-500 dark:text-zinc-400 text-xs font-mono mb-2">
                <BookOpen className="h-3.5 w-3.5 text-[#059669] dark:text-[#10B981]" />
                <span>Equivalent Volume</span>
              </div>
              <motion.div
                key={booksPerYear}
                initial={{ opacity: 0.5, y: -4 }}
                animate={{ opacity: 1, y: 0 }}
                className="text-xl sm:text-2xl lg:text-3xl font-bold font-mono text-zinc-950 dark:text-white"
              >
                ~{booksPerYear} books <span className="text-xs text-zinc-500 dark:text-zinc-500 font-normal">/ yr</span>
              </motion.div>
              <p className="mt-2 text-[11px] text-zinc-600 dark:text-zinc-400 leading-relaxed">
                At average 250 pages/book, finish your entire pending reading queue within twelve months.
              </p>
            </motion.div>

            <motion.div
              whileHover={{ y: -3 }}
              transition={{ duration: 0.2 }}
              className="rounded-xl border border-black/[0.06] dark:border-white/[0.06] bg-zinc-50 dark:bg-[#12151B] p-4 sm:p-5 shadow-sm"
            >
              <div className="flex items-center gap-2 text-zinc-500 dark:text-zinc-400 text-xs font-mono mb-2">
                <TrendingUp className="h-3.5 w-3.5 text-[#059669] dark:text-[#10B981]" />
                <span>Audible Credit Parity</span>
              </div>
              <motion.div
                key={savings}
                initial={{ opacity: 0.5, y: -4 }}
                animate={{ opacity: 1, y: 0 }}
                className="text-xl sm:text-2xl lg:text-3xl font-bold font-mono text-[#059669] dark:text-[#10B981]"
              >
                ${savings} <span className="text-xs text-zinc-500 dark:text-zinc-500 font-normal">saved / yr</span>
              </motion.div>
              <p className="mt-2 text-[11px] text-zinc-600 dark:text-zinc-400 leading-relaxed">
                Compare to paying $15/credit for {booksPerYear} audiobooks ($ {audibleCreditCost}/yr on conventional retail).
              </p>
            </motion.div>
          </div>
        </motion.div>
      </div>
    </section>
  );
};
