"use client";

import React, { useState } from "react";
import { ArrowRight, Volume2, ShieldCheck, Download, Smartphone, Play, Pause } from "lucide-react";
import { WaveformVisualizer } from "./WaveformVisualizer";
import { pulseTap, useHeroEntrance, useMagnetic } from "@/lib/anime-motion";

interface HeroSectionProps {
  onExplorePlans: () => void;
}

const HERO_BARS = Array.from({ length: 48 }, (_, i) => i);

export const HeroSection: React.FC<HeroSectionProps> = ({ onExplorePlans }) => {
  const [heroPlaying, setHeroPlaying] = useState(false);
  const [speed, setSpeed] = useState(1.25);
  const rootRef = useHeroEntrance(true);
  const ctaMagnetic = useMagnetic<HTMLButtonElement>(18);
  const labMagnetic = useMagnetic<HTMLAnchorElement>(18);

  const toggleHeroAudio = (e: React.MouseEvent<HTMLButtonElement>) => {
    pulseTap(e.currentTarget);
    if (typeof window === "undefined" || !("speechSynthesis" in window)) {
      setHeroPlaying(!heroPlaying);
      return;
    }
    if (heroPlaying) {
      window.speechSynthesis.cancel();
      setHeroPlaying(false);
    } else {
      window.speechSynthesis.cancel();
      const u = new SpeechSynthesisUtterance(
        "The studio was filled with the rich odour of roses, and when the light summer wind stirred amidst the trees of the garden, there came through the open door the heavy scent of the lilac."
      );
      u.rate = speed;
      u.onend = () => setHeroPlaying(false);
      u.onerror = () => setHeroPlaying(false);
      window.speechSynthesis.speak(u);
      setHeroPlaying(true);
    }
  };

  const cycleSpeed = () => {
    const list = [1.0, 1.25, 1.5, 2.0];
    setSpeed(list[(list.indexOf(speed) + 1) % list.length]);
  };

  return (
    <section
      ref={rootRef as React.RefObject<HTMLElement>}
      className="relative hero-field overflow-hidden min-h-[100svh] flex flex-col"
    >
      {/* Animated listening field — sits under copy, masked so brand stays dominant */}
      <div
        className="hero-bars pointer-events-none absolute inset-x-0 top-[42%] bottom-[4%] flex items-end justify-center gap-1 sm:gap-1.5 px-3 sm:px-8 z-[1]"
        aria-hidden
      >
        {HERO_BARS.map((i) => (
          <span
            key={i}
            data-hero-bar
            className="hero-bar block w-1 sm:w-1.5 origin-bottom rounded-full bg-emerald"
            style={{
              height: `${36 + ((i * 41) % 44)}%`,
              opacity: 0.42,
              transform: "scaleY(0.55)",
            }}
          />
        ))}
      </div>

      <div className="relative z-10 mx-auto w-full max-w-5xl px-4 sm:px-6 pt-20 sm:pt-28 pb-20 sm:pb-28 flex flex-col items-center text-center flex-1 justify-center">
        <p
          data-hero-brand
          className="font-display text-[clamp(3.5rem,15vw,8.75rem)] font-bold tracking-tighter leading-[0.86] text-white"
        >
          AudioBy
        </p>

        <h1
          data-hero-line
          className="mt-6 sm:mt-8 max-w-2xl font-display text-xl sm:text-3xl md:text-[2.35rem] font-semibold tracking-tight text-white leading-[1.15]"
        >
          Your books and documents, spoken with clarity.
        </h1>

        <p
          data-hero-line
          className="mt-4 sm:mt-5 max-w-[36rem] text-sm sm:text-base text-white/82 leading-relaxed"
        >
          Import papers and notes—or stream 70,000+ public classics. Lifelike narration, chapter tracking, and offline playback on iOS and web.
        </p>

        <div className="mt-9 sm:mt-11 flex flex-col sm:flex-row items-center justify-center gap-3 w-full sm:w-auto">
          <button
            ref={ctaMagnetic}
            data-hero-cta
            data-magnetic
            type="button"
            onClick={(e) => {
              pulseTap(e.currentTarget);
              onExplorePlans();
            }}
            className="w-full sm:w-auto inline-flex items-center justify-center gap-2 rounded-xl bg-emerald px-6 py-3.5 text-sm font-bold text-emerald-ink shadow-lift hover:bg-emerald-light transition-colors"
          >
            <span>Upgrade to Plus or Premium</span>
            <ArrowRight className="h-4 w-4" />
          </button>

          <a
            ref={labMagnetic}
            data-hero-cta
            data-magnetic
            href="#lab"
            className="w-full sm:w-auto inline-flex items-center justify-center gap-2 rounded-xl border border-white/25 bg-transparent px-5 py-3.5 text-sm font-semibold text-white hover:bg-white/10 transition-colors"
          >
            <Volume2 className="h-4 w-4 text-emerald" />
            <span>Try the Voice Lab</span>
          </a>
        </div>

        {/* Studio player */}
        <div
          data-hero-player
          className="mt-14 sm:mt-16 w-full max-w-xl rounded-2xl border border-white/12 bg-leaf-raised p-4 sm:p-6 text-left shadow-lift text-leaf-ink"
        >
          <div className="flex items-center justify-between pb-4 border-b border-[var(--border-subtle)] mb-4 gap-2">
            <div className="flex items-center gap-3 min-w-0">
              <button
                type="button"
                onClick={toggleHeroAudio}
                className="h-11 w-11 rounded-xl bg-emerald text-emerald-ink flex items-center justify-center shrink-0 hover:bg-emerald-dark dark:hover:bg-emerald-light transition-colors"
                aria-label={heroPlaying ? "Pause audio" : "Play audio"}
              >
                {heroPlaying ? <Pause className="h-4 w-4" /> : <Play className="h-4 w-4 ml-0.5" />}
              </button>
              <div className="min-w-0">
                <p className="text-sm font-bold tracking-tight truncate font-display">
                  The Picture of Dorian Gray
                </p>
                <p className="text-xs text-leaf-muted truncate">
                  Oscar Wilde · Chapter 1
                </p>
              </div>
            </div>
            <span className="rounded-md bg-emerald/15 border border-emerald/25 px-2 py-0.5 text-[10px] uppercase text-emerald-dark dark:text-emerald flex items-center gap-1.5 shrink-0 font-semibold tracking-wide">
              <span className={`h-1.5 w-1.5 rounded-full bg-emerald ${heroPlaying ? "animate-pulse" : ""}`} />
              Neural
            </span>
          </div>

          <div className="rounded-xl bg-leaf-surface dark:bg-leaf-field/80 p-3 border border-[var(--border-subtle)]">
            <div className="flex items-center justify-between text-[10px] text-leaf-faint mb-2 uppercase tracking-wide">
              <span>Acoustic spectrum</span>
              <span className="text-emerald-dark dark:text-emerald">
                {heroPlaying ? "Live" : "Ready"}
              </span>
            </div>
            <WaveformVisualizer isPlaying={heroPlaying} barCount={36} height={36} />
          </div>

          <div className="mt-4 space-y-2">
            <div className="flex items-center justify-between text-[11px] text-leaf-faint tabular-nums">
              <span>04:18</span>
              <span>-18:42</span>
            </div>
            <div className="h-1.5 w-full bg-black/10 dark:bg-white/10 rounded-full overflow-hidden">
              <div
                className="h-full bg-emerald rounded-full transition-[width] duration-700"
                style={{ width: heroPlaying ? "42%" : "28%" }}
              />
            </div>
          </div>

          <div className="mt-4 pt-3 border-t border-[var(--border-subtle)] flex flex-wrap items-center justify-between gap-2 text-xs text-leaf-muted">
            <button
              type="button"
              onClick={cycleSpeed}
              className="rounded-md bg-leaf-surface dark:bg-white/5 border border-[var(--border-subtle)] px-2 py-1 text-[11px] text-leaf-ink hover:border-emerald/40 transition-colors"
            >
              {speed}x speed
            </button>
            <span className="text-[11px] text-emerald-dark dark:text-emerald font-medium">
              Offline ready
            </span>
          </div>
        </div>

        <div
          data-hero-line
          className="mt-9 flex flex-wrap items-center justify-center gap-x-5 gap-y-2 text-[11px] text-white/60"
        >
          <span className="flex items-center gap-1.5">
            <ShieldCheck className="h-3.5 w-3.5 text-emerald shrink-0" />
            Free classics, no account
          </span>
          <span className="flex items-center gap-1.5">
            <Download className="h-3.5 w-3.5 text-emerald shrink-0" />
            Offline player
          </span>
          <span className="flex items-center gap-1.5">
            <Smartphone className="h-3.5 w-3.5 text-emerald shrink-0" />
            Syncs to iOS
          </span>
        </div>
      </div>
    </section>
  );
};
