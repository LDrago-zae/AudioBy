"use client";

import React, { useState } from "react";
import { Clock, BookOpen, TrendingUp } from "lucide-react";
import { useScrollReveal } from "@/lib/anime-motion";

export const TimeCalculator: React.FC = () => {
  const [pagesPerWeek, setPagesPerWeek] = useState(100);
  const ref = useScrollReveal<HTMLElement>();

  const hoursPerWeek = ((pagesPerWeek * 1.4) / 60).toFixed(1);
  const hoursPerYear = Math.round(Number(hoursPerWeek) * 52);
  const booksPerYear = Math.max(1, Math.round((pagesPerWeek * 52) / 250));
  const audibleCreditCost = booksPerYear * 15;
  const audioByAnnualCost = 348;
  const savings = Math.max(0, audibleCreditCost - audioByAnnualCost);

  return (
    <section
      id="calculator"
      ref={ref}
      className="py-16 sm:py-24 border-t border-[var(--border-subtle)] bg-[var(--background)]"
    >
      <div className="mx-auto max-w-5xl px-4 sm:px-6">
        <div className="text-center max-w-2xl mx-auto mb-10 sm:mb-14">
          <h2
            data-reveal
            className="font-display text-3xl sm:text-5xl font-bold tracking-tight text-leaf-ink"
          >
            Calculate hours unlocked.
          </h2>
          <p data-reveal className="mt-3 text-sm sm:text-base text-leaf-muted">
            See how screen-locked reading becomes flexible audio on walks, commutes, and rest.
          </p>
        </div>

        <div
          data-reveal
          className="rounded-2xl border border-[var(--border-subtle)] bg-leaf-raised p-5 sm:p-8 md:p-10 shadow-soft"
        >
          <div className="pb-8 border-b border-[var(--border-subtle)]">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2.5 mb-4">
              <label className="text-sm font-semibold text-leaf-ink">
                Weekly document & book reading load
              </label>
              <span className="self-start sm:self-auto rounded-lg bg-emerald/15 border border-emerald/30 px-3 py-1 text-sm font-bold text-emerald-dark dark:text-emerald tabular-nums">
                {pagesPerWeek} pages / week
              </span>
            </div>

            <input
              type="range"
              min={20}
              max={400}
              step={10}
              value={pagesPerWeek}
              onChange={(e) => setPagesPerWeek(Number(e.target.value))}
              className="w-full h-2.5 bg-black/10 dark:bg-white/10 rounded-lg appearance-none cursor-pointer accent-emerald"
            />

            <div className="flex justify-between text-[11px] text-leaf-faint mt-2.5">
              <span>20p casual</span>
              <span className="hidden sm:inline">150p student</span>
              <span>400p academic</span>
            </div>
          </div>

          <div className="mt-8 grid grid-cols-1 sm:grid-cols-3 gap-4 sm:gap-6">
            <div className="rounded-xl border border-[var(--border-subtle)] bg-leaf-surface p-5">
              <div className="flex items-center gap-2 text-leaf-faint text-xs mb-2">
                <Clock className="h-3.5 w-3.5 text-emerald-dark dark:text-emerald" />
                <span>Audio time recovered</span>
              </div>
              <p className="font-display text-2xl sm:text-3xl font-bold text-leaf-ink tabular-nums">
                {hoursPerWeek} hrs{" "}
                <span className="text-xs text-leaf-faint font-normal">/ wk</span>
              </p>
              <p className="mt-2 text-[11px] text-leaf-muted leading-relaxed">
                Turn {hoursPerYear} hours per year of screen fatigue into listening while walking, cooking, or commuting.
              </p>
            </div>

            <div className="rounded-xl border border-[var(--border-subtle)] bg-leaf-surface p-5">
              <div className="flex items-center gap-2 text-leaf-faint text-xs mb-2">
                <BookOpen className="h-3.5 w-3.5 text-emerald-dark dark:text-emerald" />
                <span>Equivalent volume</span>
              </div>
              <p className="font-display text-2xl sm:text-3xl font-bold text-leaf-ink tabular-nums">
                ~{booksPerYear} books{" "}
                <span className="text-xs text-leaf-faint font-normal">/ yr</span>
              </p>
              <p className="mt-2 text-[11px] text-leaf-muted leading-relaxed">
                At ~250 pages/book, clear a pending reading list within twelve months.
              </p>
            </div>

            <div className="rounded-xl border border-[var(--border-subtle)] bg-leaf-surface p-5">
              <div className="flex items-center gap-2 text-leaf-faint text-xs mb-2">
                <TrendingUp className="h-3.5 w-3.5 text-emerald-dark dark:text-emerald" />
                <span>Credit parity</span>
              </div>
              <p className="font-display text-2xl sm:text-3xl font-bold text-emerald-dark dark:text-emerald tabular-nums">
                ${savings}{" "}
                <span className="text-xs text-leaf-faint font-normal">saved / yr</span>
              </p>
              <p className="mt-2 text-[11px] text-leaf-muted leading-relaxed">
                Versus $15/credit for {booksPerYear} titles (${audibleCreditCost}/yr retail).
              </p>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
};
