"use client";

import React from "react";
import { Headphones, ArrowUpRight } from "lucide-react";

export const Footer: React.FC = () => {
  return (
    <footer className="border-t border-black/[0.08] dark:border-white/[0.08] bg-[#F1F5F2] dark:bg-[#080B09] py-10 sm:py-14 text-zinc-500 dark:text-ink-muted text-xs pb-24 sm:pb-14 transition-colors duration-200">
      <div className="mx-auto max-w-6xl px-3.5 sm:px-6">
        <div className="flex flex-col md:flex-row items-start md:items-center justify-between gap-6">
          {/* Logo & Tagline */}
          <div className="flex items-center gap-3">
            <div className="flex h-7 w-7 items-center justify-center rounded-lg bg-white dark:bg-[#141C17] text-[#0F9B51] dark:text-emerald border border-black/[0.08] dark:border-white/10 shrink-0 shadow-sm">
              <Headphones className="h-3.5 w-3.5" />
            </div>
            <div>
              <p className="font-bold text-zinc-900 dark:text-white text-xs">AudioBy</p>
              <p className="text-[10px] sm:text-[11px] text-zinc-500 dark:text-ink-muted">
                Turn any book or PDF document into immersive, clear audio.
              </p>
            </div>
          </div>

          {/* Links */}
          <div className="grid grid-cols-2 xs:flex xs:flex-wrap items-center gap-x-6 gap-y-2.5 text-xs text-zinc-600 dark:text-ink-secondary w-full md:w-auto">
            <a href="#problem" className="hover:text-zinc-900 dark:hover:text-white transition-colors">
              Why AudioBy
            </a>
            <a href="#lab" className="hover:text-zinc-900 dark:hover:text-white transition-colors">
              Voice Lab
            </a>
            <a href="#calculator" className="hover:text-zinc-900 dark:hover:text-white transition-colors">
              Time Saved
            </a>
            <a href="#pricing" className="hover:text-zinc-900 dark:hover:text-white transition-colors">
              Pricing
            </a>
            <a href="#faq" className="hover:text-zinc-900 dark:hover:text-white transition-colors">
              FAQ
            </a>
            <a
              href="https://apps.apple.com/app/audioby/id6807599877"
              target="_blank"
              rel="noreferrer"
              className="inline-flex items-center gap-1 text-[#0F9B51] dark:text-emerald hover:underline font-mono font-medium"
            >
              <span>App Store</span>
              <ArrowUpRight className="h-3 w-3" />
            </a>
          </div>
        </div>

        <div className="mt-8 sm:mt-10 pt-5 sm:pt-6 border-t border-black/[0.06] dark:border-white/[0.04] flex flex-col sm:flex-row items-start sm:items-center justify-between gap-2 text-[10px] sm:text-[11px] text-zinc-400 dark:text-ink-muted font-mono">
          <p>© {new Date().getFullYear()} AudioBy. All rights reserved.</p>
          <p>Multiplatform service supported under App Store Guideline 3.1.3(b).</p>
        </div>
      </div>
    </footer>
  );
};
