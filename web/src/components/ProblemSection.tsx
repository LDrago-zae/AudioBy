"use client";

import React from "react";
import { AnimeWavePath } from "@/components/AnimeWavePath";
import { useScrollReveal, useSplitHeading } from "@/lib/anime-motion";

const PROBLEMS = [
  {
    title: "Robotic synthesizers cause auditory exhaustion",
    detail:
      "Flat machine cadence forces your auditory cortex to work overtime. After ten minutes, long-form listening becomes a chore.",
    resolution: "Natural cadence acoustic synthesis",
  },
  {
    title: "PDF formatting breaks standard readers",
    detail:
      "Headers, citations, and footnotes get spoken aloud. Academic papers turn into noise instead of a lecture.",
    resolution: "Intelligent layout & footnote filtering",
  },
  {
    title: "Streaming apps lock you out when offline",
    detail:
      "DRM wrappers and always-online players fail the moment you step into a subway or onto a flight.",
    resolution: "100% offline local audio cache",
  },
];

export const ProblemSection: React.FC = () => {
  const revealRef = useScrollReveal<HTMLElement>();
  const splitRef = useSplitHeading<HTMLElement>();

  return (
    <section
      id="problem"
      ref={(node) => {
        (revealRef as React.MutableRefObject<HTMLElement | null>).current = node;
        (splitRef as React.MutableRefObject<HTMLElement | null>).current = node;
      }}
      className="py-16 sm:py-24 border-t border-[var(--border-subtle)] bg-[var(--background)] relative overflow-hidden"
    >
      <AnimeWavePath className="absolute inset-x-0 bottom-8 opacity-40" />

      <div className="relative mx-auto max-w-6xl px-4 sm:px-6">
        <div className="max-w-3xl mb-12 sm:mb-16">
          <h2
            data-split
            className="font-display text-3xl sm:text-5xl font-bold tracking-tight text-leaf-ink leading-[1.1]"
          >
            You didn’t lose focus.
          </h2>
          <p data-reveal className="mt-3 text-xl sm:text-2xl text-leaf-muted font-semibold font-display">
            The tools were designed for screens, not ears.
          </p>
        </div>

        <div className="grid gap-8 sm:gap-10">
          {PROBLEMS.map((item) => (
            <article
              key={item.title}
              data-reveal
              className="grid sm:grid-cols-[1fr_auto] gap-4 sm:gap-8 items-start border-t border-[var(--border-subtle)] pt-8"
            >
              <div>
                <h3 className="font-display text-xl sm:text-2xl font-bold tracking-tight text-leaf-ink">
                  {item.title}
                </h3>
                <p className="mt-3 max-w-measure text-sm sm:text-base text-leaf-muted leading-relaxed">
                  {item.detail}
                </p>
              </div>
              <p className="text-sm font-semibold text-emerald-dark dark:text-emerald sm:text-right sm:max-w-[14rem]">
                {item.resolution}
              </p>
            </article>
          ))}
        </div>
      </div>
    </section>
  );
};
