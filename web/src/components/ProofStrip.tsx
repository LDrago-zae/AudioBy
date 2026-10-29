"use client";

import React from "react";
import { AnimeWavePath } from "@/components/AnimeWavePath";
import { useAnimeCounter, useScrollReveal, useSplitHeading } from "@/lib/anime-motion";

const Counter: React.FC<{ target: number; suffix?: string }> = ({ target, suffix = "" }) => {
  const ref = useAnimeCounter(target, suffix);
  return (
    <span ref={ref} className="tabular-nums">
      0{suffix}
    </span>
  );
};

const STATS = [
  {
    value: <Counter target={70000} suffix="+" />,
    label: "Curated public classics",
    detail: "Available instantly via Gutenberg & LibriVox",
  },
  {
    value: "0 bytes",
    label: "Leave your device",
    detail: "Private on-device neural synthesis option",
  },
  {
    value: "< 500 ms",
    label: "First syllable latency",
    detail: "Immediate audio from a cold start",
  },
  {
    value: "100%",
    label: "Offline cached playback",
    detail: "Airplanes, subways, and remote wilderness",
  },
];

export const ProofStrip: React.FC = () => {
  const revealRef = useScrollReveal<HTMLElement>();
  const splitRef = useSplitHeading<HTMLElement>();

  return (
    <section
      ref={(node) => {
        (revealRef as React.MutableRefObject<HTMLElement | null>).current = node;
        (splitRef as React.MutableRefObject<HTMLElement | null>).current = node;
      }}
      className="border-y border-[var(--border-subtle)] bg-leaf-surface paper-grain relative overflow-hidden"
    >
      <AnimeWavePath className="absolute inset-x-0 top-0 opacity-45" />

      <div className="relative mx-auto max-w-6xl px-4 sm:px-6 py-16 sm:py-20">
        <h2
          data-split
          className="font-display text-2xl sm:text-4xl font-bold tracking-tight text-leaf-ink max-w-2xl leading-[1.12]"
        >
          Built for long listening, not ten-minute demos.
        </h2>

        <div className="mt-12 sm:mt-14 grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-x-8 gap-y-10">
          {STATS.map((stat) => (
            <div
              key={stat.label}
              data-reveal
              className="flex flex-col border-t border-[var(--border-subtle)] pt-5"
            >
              <span className="font-display text-2xl sm:text-3xl font-bold tracking-tight text-leaf-ink">
                {stat.value}
              </span>
              <span className="mt-3 text-sm font-semibold text-leaf-ink">{stat.label}</span>
              <span className="mt-1.5 text-xs text-leaf-muted leading-relaxed max-w-[22ch]">
                {stat.detail}
              </span>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
};
