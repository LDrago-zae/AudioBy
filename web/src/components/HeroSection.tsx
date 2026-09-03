"use client";

import React, { useState } from "react";
import { motion } from "motion/react";
import { ArrowRight, Volume2, ArrowDown, ShieldCheck, Download, Smartphone, Play, Pause } from "lucide-react";
import { WaveformVisualizer } from "./WaveformVisualizer";

interface HeroSectionProps {
  onExplorePlans: () => void;
}

export const HeroSection: React.FC<HeroSectionProps> = ({ onExplorePlans }) => {
  const [heroPlaying, setHeroPlaying] = useState(false);
  const [speed, setSpeed] = useState(1.25);

  const toggleHeroAudio = () => {
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
    const next = list[(list.indexOf(speed) + 1) % list.length];
    setSpeed(next);
  };

  return (
    <section className="relative atmosphere-ambient pt-12 pb-16 sm:pt-20 sm:pb-24 md:pt-24 md:pb-28 overflow-hidden">
      <div className="mx-auto max-w-5xl px-3.5 sm:px-6 text-center">
        {/* Hardware-inspired Eyebrow pill */}
        <motion.div
          initial={{ opacity: 0, y: -10 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, ease: "easeOut" }}
          className="inline-flex items-center gap-2 rounded-full border border-black/[0.08] dark:border-white/[0.10] bg-black/[0.02] dark:bg-[#12151B] px-3.5 py-1 text-xs text-zinc-700 dark:text-zinc-300 shadow-sm mb-6 sm:mb-8 max-w-full"
        >
          <span className="h-1.5 w-1.5 rounded-full bg-[#10B981] shrink-0" />
          <span className="font-mono text-[10px] sm:text-[11px] uppercase tracking-wider text-zinc-800 dark:text-zinc-200">
            <span className="hidden sm:inline">ElevenLabs Neural Synthesis & Document Engine</span>
            <span className="sm:hidden">ElevenLabs AI & PDF Reader</span>
          </span>
          <span className="text-zinc-400 dark:text-zinc-600">·</span>
          <span className="font-mono text-[10px] text-[#059669] dark:text-[#10B981] font-semibold">v1.2</span>
        </motion.div>

        {/* Main Title */}
        <motion.h1
          initial={{ opacity: 0, y: 16 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.1, ease: [0.16, 1, 0.3, 1] }}
          className="text-3xl sm:text-5xl md:text-7xl font-bold tracking-tighter text-zinc-950 dark:text-white max-w-4xl mx-auto leading-[1.1] sm:leading-[1.05]"
        >
          Your books and documents,{" "}
          <span className="text-[#059669] dark:text-[#10B981] font-serif italic font-normal block sm:inline">
            spoken with clarity.
          </span>
        </motion.h1>

        {/* Subtitle */}
        <motion.p
          initial={{ opacity: 0, y: 16 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.2, ease: [0.16, 1, 0.3, 1] }}
          className="mt-4 sm:mt-6 max-w-2xl mx-auto text-xs sm:text-base md:text-lg text-zinc-600 dark:text-zinc-400 leading-relaxed px-2 sm:px-0"
        >
          Import academic papers, books, or lecture notes—or stream over 70,000 public classics. Experience lifelike narration with intelligent chapter tracking and complete offline playback.
        </motion.p>

        {/* CTA Buttons */}
        <motion.div
          initial={{ opacity: 0, y: 16 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.3, ease: [0.16, 1, 0.3, 1] }}
          className="mt-7 sm:mt-9 flex flex-col sm:flex-row items-center justify-center gap-2.5 sm:gap-3"
        >
          <motion.button
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
            onClick={onExplorePlans}
            className="w-full sm:w-auto inline-flex items-center justify-center gap-2 rounded-xl bg-[#10B981] hover:bg-[#059669] dark:hover:bg-[#34D399] px-6 py-3 text-xs sm:text-sm font-semibold text-black transition-all shadow-sm shadow-emerald-500/20"
          >
            <span>Upgrade to Plus or Premium</span>
            <ArrowRight className="h-4 w-4" />
          </motion.button>

          <motion.a
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
            href="#lab"
            className="w-full sm:w-auto inline-flex items-center justify-center gap-2 rounded-xl border border-black/[0.1] dark:border-white/[0.12] bg-white dark:bg-[#12151B] px-5 py-3 text-xs sm:text-sm font-medium text-zinc-800 dark:text-zinc-200 hover:bg-zinc-50 dark:hover:bg-[#181D24] hover:border-black/20 dark:hover:border-white/20 transition-all shadow-sm"
          >
            <Volume2 className="h-4 w-4 text-[#059669] dark:text-[#10B981]" />
            <span>Interactive Voice Lab</span>
            <ArrowDown className="h-3.5 w-3.5 text-zinc-400 dark:text-zinc-500" />
          </motion.a>
        </motion.div>

        {/* Studio Acoustic Player Mockup */}
        <motion.div
          initial={{ opacity: 0, y: 28, scale: 0.97 }}
          animate={{ opacity: 1, y: 0, scale: 1 }}
          transition={{ duration: 0.7, delay: 0.4, type: "spring", damping: 22 }}
          whileHover={{ y: -3, transition: { duration: 0.2 } }}
          className="mt-10 sm:mt-14 mx-auto max-w-xl rounded-2xl border border-black/[0.08] dark:border-white/[0.10] bg-white dark:bg-[#0E1015] p-4 sm:p-6 text-left shadow-lg dark:shadow-console transition-colors"
        >
          {/* Top Player bar */}
          <div className="flex items-center justify-between pb-3 sm:pb-4 border-b border-black/[0.06] dark:border-white/[0.08] mb-4 sm:mb-5 gap-2">
            <div className="flex items-center gap-2.5 sm:gap-3 min-w-0">
              <motion.button
                whileTap={{ scale: 0.92 }}
                onClick={toggleHeroAudio}
                className="h-10 w-10 sm:h-11 sm:w-11 rounded-xl bg-[#10B981] hover:bg-[#059669] dark:hover:bg-[#34D399] text-black flex items-center justify-center font-bold shadow-sm transition-colors shrink-0"
                aria-label={heroPlaying ? "Pause audio" : "Play audio"}
              >
                {heroPlaying ? <Pause className="h-4 w-4" /> : <Play className="h-4 w-4 ml-0.5" />}
              </motion.button>
              <div className="min-w-0">
                <p className="text-xs sm:text-sm font-bold text-zinc-900 dark:text-white tracking-tight truncate">
                  The Picture of Dorian Gray
                </p>
                <p className="text-[10px] sm:text-xs text-zinc-500 dark:text-zinc-400 truncate">
                  Oscar Wilde · Chapter 1: The Studio
                </p>
              </div>
            </div>

            <span className="rounded-md bg-emerald-500/10 border border-emerald-500/20 px-2 py-0.5 text-[9px] sm:text-[10px] font-mono uppercase text-[#059669] dark:text-[#10B981] flex items-center gap-1.5 shrink-0 font-medium">
              <span className={`h-1.5 w-1.5 rounded-full bg-[#10B981] ${heroPlaying ? "animate-ping" : ""}`} />
              <span>Studio A · Neural</span>
            </span>
          </div>

          {/* Sunken Waveform Console */}
          <div className="rounded-xl border border-black/[0.06] dark:border-white/[0.06] bg-zinc-50 dark:bg-[#060709] p-3 my-2 sm:my-3 shadow-inner">
            <div className="flex items-center justify-between text-[9px] sm:text-[10px] font-mono text-zinc-500 dark:text-zinc-500 mb-2">
              <span className="tracking-wider uppercase">Acoustic Spectrum (44.1 kHz)</span>
              <span className="text-[#059669] dark:text-[#10B981]">
                {heroPlaying ? "Streaming Live" : "Ready"}
              </span>
            </div>
            <WaveformVisualizer isPlaying={heroPlaying} barCount={32} height={34} />
          </div>

          {/* Scrub & Timestamps */}
          <div className="space-y-1.5 sm:space-y-2 mt-3 sm:mt-4">
            <div className="flex items-center justify-between text-[10px] sm:text-[11px] font-mono text-zinc-500 dark:text-zinc-400">
              <span>04:18</span>
              <span className="text-zinc-500 text-[9px] sm:text-[10px] hidden xs:inline sm:inline">
                Acoustic breath modeling active
              </span>
              <span>-18:42</span>
            </div>

            <div className="h-1.5 w-full bg-zinc-200 dark:bg-[#1A1D24] rounded-full overflow-hidden">
              <motion.div
                className="h-full bg-[#10B981] rounded-full"
                animate={{ width: heroPlaying ? "42%" : "28%" }}
                transition={{ duration: 1 }}
              />
            </div>
          </div>

          {/* Bottom Indicators */}
          <div className="mt-3 sm:mt-4 pt-2.5 sm:pt-3 border-t border-black/[0.04] dark:border-white/[0.06] flex flex-col xs:flex-row items-start xs:items-center justify-between gap-2 text-xs text-zinc-600 dark:text-zinc-400">
            <div className="flex items-center gap-2">
              <button
                onClick={cycleSpeed}
                title="Click to toggle speed"
                className="rounded-md bg-zinc-100 dark:bg-[#161920] border border-black/[0.08] dark:border-white/[0.1] px-2 py-0.5 font-mono text-[10px] sm:text-[11px] text-zinc-800 dark:text-zinc-200 hover:border-[#10B981]/50 transition-colors cursor-pointer"
              >
                {speed}x Speed
              </button>
              <span className="text-[10px] sm:text-[11px] text-zinc-500 dark:text-zinc-500 font-mono">Pitch-locked</span>
            </div>

            <div className="flex items-center gap-2.5 text-[10px] sm:text-[11px] text-zinc-500 dark:text-zinc-400 self-end xs:self-auto font-mono">
              <span className="flex items-center gap-1.5">
                <span className="h-1.5 w-1.5 rounded-full bg-[#10B981]" />
                Auto-sleep: Chapter end
              </span>
              <span className="rounded bg-zinc-100 dark:bg-[#161920] px-1.5 sm:px-2 py-0.5 font-mono text-[9px] sm:text-[10px] text-[#059669] dark:text-[#10B981] border border-[#10B981]/25">
                Offline Ready
              </span>
            </div>
          </div>
        </motion.div>

        {/* Micro guarantees */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ duration: 0.8, delay: 0.6 }}
          className="mt-6 flex flex-wrap items-center justify-center gap-x-5 gap-y-2 text-[10px] sm:text-[11px] text-zinc-500 dark:text-zinc-500 font-mono px-2"
        >
          <span className="flex items-center gap-1.5">
            <ShieldCheck className="h-3 w-3 sm:h-3.5 sm:w-3.5 text-[#059669] dark:text-[#10B981] shrink-0" />
            No account required for free books
          </span>
          <span className="flex items-center gap-1.5">
            <Download className="h-3 w-3 sm:h-3.5 sm:w-3.5 text-[#059669] dark:text-[#10B981] shrink-0" />
            100% Offline player
          </span>
          <span className="flex items-center gap-1.5">
            <Smartphone className="h-3 w-3 sm:h-3.5 sm:w-3.5 text-[#059669] dark:text-[#10B981] shrink-0" />
            Syncs to iOS App
          </span>
        </motion.div>
      </div>
    </section>
  );
};
