"use client";

import React from "react";
import { ArrowUpRight } from "lucide-react";
import { AudioByMark } from "@/components/AudioByMark";

export const Footer: React.FC = () => {
  return (
    <footer className="border-t border-[var(--border-subtle)] bg-leaf-field text-white/70 py-12 sm:py-16 text-sm pb-28 sm:pb-16">
      <div className="mx-auto max-w-6xl px-4 sm:px-6">
        <div className="flex flex-col md:flex-row items-start md:items-center justify-between gap-8">
          <div className="flex items-center gap-3">
            <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-emerald text-emerald-ink shrink-0">
              <AudioByMark className="h-4 w-4" />
            </div>
            <div>
              <p className="font-display font-bold text-white text-base">AudioBy</p>
              <p className="text-xs text-white/55 max-w-xs">
                Turn any book or PDF into clear, immersive audio.
              </p>
            </div>
          </div>

          <div className="flex flex-wrap items-center gap-x-6 gap-y-2 text-sm text-white/65">
            <a href="#problem" className="hover:text-white transition-colors">
              Why AudioBy
            </a>
            <a href="#lab" className="hover:text-white transition-colors">
              Voice Lab
            </a>
            <a href="#pricing" className="hover:text-white transition-colors">
              Pricing
            </a>
            <a href="#faq" className="hover:text-white transition-colors">
              FAQ
            </a>
            <a
              href="https://apps.apple.com/app/audioby/id6807599877"
              target="_blank"
              rel="noreferrer"
              className="inline-flex items-center gap-1 text-emerald hover:underline font-semibold"
            >
              App Store
              <ArrowUpRight className="h-3 w-3" />
            </a>
          </div>
        </div>

        <div className="mt-10 pt-6 border-t border-white/10 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-2 text-xs text-white/40">
          <p>© {new Date().getFullYear()} AudioBy. All rights reserved.</p>
          <p>Multiplatform service supported under App Store Guideline 3.1.3(b).</p>
        </div>
      </div>
    </footer>
  );
};
