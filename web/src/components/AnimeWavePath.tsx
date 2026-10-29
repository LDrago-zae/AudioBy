"use client";

import React from "react";
import { useScrollSync } from "@/lib/anime-motion";

/** Scroll-scrubbed SVG waveform — anime.js createDrawable + onScroll sync. */
export const AnimeWavePath: React.FC<{ className?: string }> = ({ className = "" }) => {
  const ref = useScrollSync<HTMLDivElement>();

  return (
    <div ref={ref} className={`pointer-events-none ${className}`} aria-hidden>
      <svg
        viewBox="0 0 720 120"
        className="w-full h-auto text-emerald-dark/40 dark:text-emerald/35"
        fill="none"
      >
        <path
          data-draw
          d="M0 72 C40 72 40 28 80 28 S120 72 160 72 S200 20 240 20 S280 90 320 90 S360 40 400 40 S440 80 480 80 S520 24 560 24 S600 70 640 70 S680 48 720 48"
          stroke="currentColor"
          strokeWidth="3"
          strokeLinecap="round"
          strokeLinejoin="round"
        />
        <path
          data-draw
          d="M0 84 C50 84 50 50 100 50 S150 96 200 96 S250 36 300 36 S350 88 400 88 S450 54 500 54 S550 92 600 92 S650 60 720 60"
          stroke="currentColor"
          strokeWidth="2"
          strokeLinecap="round"
          opacity="0.55"
        />
      </svg>
      <div
        data-parallax="24"
        className="absolute inset-x-0 top-1/2 -translate-y-1/2 h-px bg-gradient-to-r from-transparent via-emerald/40 to-transparent"
      />
    </div>
  );
};
