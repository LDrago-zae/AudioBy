"use client";

import React, { useState, useEffect, useRef } from "react";
import { motion, AnimatePresence } from "motion/react";
import { Play, Pause } from "lucide-react";
import { WaveformVisualizer } from "./WaveformVisualizer";

interface Excerpt {
  id: string;
  category: string;
  title: string;
  author: string;
  text: string;
}

interface Voice {
  id: string;
  name: string;
  tag: string;
  description: string;
  rate: number;
  pitch: number;
}

const EXCERPTS: Excerpt[] = [
  {
    id: "dorian",
    category: "Classic Literature",
    title: "Dorian Gray",
    author: "Oscar Wilde",
    text: "The studio was filled with the rich odour of roses, and when the light summer wind stirred amidst the trees of the garden, there came through the open door the heavy scent of the lilac.",
  },
  {
    id: "meditations",
    category: "Stoic Philosophy",
    title: "Meditations",
    author: "Marcus Aurelius",
    text: "When you wake up in the morning, tell yourself: The people I deal with today will be meddling, ungrateful, arrogant, dishonest, jealous, and surly. They are like this because they cannot distinguish good from evil.",
  },
  {
    id: "paper",
    category: "ArXiv Research PDF",
    title: "Attention Paper",
    author: "Vaswani et al.",
    text: "The dominant sequence transduction models are based on complex recurrent or convolutional neural networks. We propose a new simple network architecture, the Transformer, based solely on attention mechanisms.",
  },
];

const VOICES: Voice[] = [
  {
    id: "adam",
    name: "ElevenLabs Adam",
    tag: "Studio Baritone",
    description: "Deep, resonant tone with natural breathing and pauses for narrative fiction.",
    rate: 0.95,
    pitch: 0.9,
  },
  {
    id: "rachel",
    name: "ElevenLabs Rachel",
    tag: "Studio Warmth",
    description: "Nuanced, conversational rhythm ideal for long essays and academic papers.",
    rate: 1.0,
    pitch: 1.05,
  },
  {
    id: "device",
    name: "On-Device Neural",
    tag: "Offline Instant",
    description: "Synthesized directly on your device. Zero cloud delay, works with no network.",
    rate: 1.05,
    pitch: 1.0,
  },
];

export const InteractivePlayer: React.FC = () => {
  const [selectedExcerpt, setSelectedExcerpt] = useState<Excerpt>(EXCERPTS[0]);
  const [selectedVoice, setSelectedVoice] = useState<Voice>(VOICES[0]);
  const [speed, setSpeed] = useState<number>(1.0);
  const [isPlaying, setIsPlaying] = useState<boolean>(false);
  const [progress, setProgress] = useState<number>(0);
  const synthRef = useRef<SpeechSynthesis | null>(null);

  useEffect(() => {
    if (typeof window !== "undefined" && "speechSynthesis" in window) {
      synthRef.current = window.speechSynthesis;
    }
    return () => {
      if (synthRef.current) synthRef.current.cancel();
    };
  }, []);

  const stopAudio = () => {
    if (synthRef.current) {
      synthRef.current.cancel();
    }
    setIsPlaying(false);
    setProgress(0);
  };

  const togglePlay = () => {
    if (isPlaying) {
      stopAudio();
      return;
    }

    if (!synthRef.current) {
      setIsPlaying(true);
      let p = 0;
      const interval = setInterval(() => {
        p += 5;
        setProgress(p);
        if (p >= 100) {
          clearInterval(interval);
          setIsPlaying(false);
          setProgress(0);
        }
      }, 200);
      return;
    }

    synthRef.current.cancel();
    const utterance = new SpeechSynthesisUtterance(selectedExcerpt.text);
    utterance.rate = selectedVoice.rate * speed;
    utterance.pitch = selectedVoice.pitch;

    utterance.onstart = () => setIsPlaying(true);
    utterance.onend = () => {
      setIsPlaying(false);
      setProgress(0);
    };
    utterance.onerror = () => {
      setIsPlaying(false);
      setProgress(0);
    };

    synthRef.current.speak(utterance);

    let curr = 0;
    const progressTimer = setInterval(() => {
      if (!synthRef.current?.speaking) {
        clearInterval(progressTimer);
        return;
      }
      curr = Math.min(curr + 5, 96);
      setProgress(curr);
    }, 250);
  };

  return (
    <section id="lab" className="py-14 sm:py-20 md:py-24 border-t border-black/[0.08] dark:border-white/[0.08] bg-[#F1F5F2] dark:bg-[#0A0D0B] relative transition-colors duration-200">
      <div className="mx-auto max-w-5xl px-3.5 sm:px-6">
        {/* Section Header */}
        <div className="text-center max-w-2xl mx-auto">
          <motion.div
            initial={{ opacity: 0, y: -10 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            className="inline-flex items-center gap-2 mb-3 text-[10px] font-mono tracking-eyebrow uppercase text-[#0F9B51] dark:text-emerald"
          >
            <span className="h-1.5 w-1.5 rounded-full bg-emerald animate-pulse" />
            <span>Interactive Voice & PDF Lab</span>
          </motion.div>

          <motion.h2
            initial={{ opacity: 0, y: 14 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ delay: 0.1 }}
            className="text-2xl sm:text-4xl md:text-5xl font-bold tracking-tight text-zinc-900 dark:text-white"
          >
            Hear Before You Sign Up
          </motion.h2>

          <motion.p
            initial={{ opacity: 0, y: 14 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ delay: 0.2 }}
            className="mt-2.5 sm:mt-3 text-xs sm:text-sm text-zinc-600 dark:text-ink-secondary"
          >
            Switch between document sources and neural voice actors to test audio clarity right inside your browser.
          </motion.p>
        </div>

        {/* The Lab Box */}
        <motion.div
          initial={{ opacity: 0, y: 24 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6, delay: 0.2 }}
          className="mt-8 sm:mt-12 rounded-2xl border border-black/[0.08] dark:border-white/10 bg-white dark:bg-[#121714] p-4 sm:p-8 shadow-lg dark:shadow-elevated transition-colors"
        >
          {/* Document Picker with Animated Pill */}
          <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-2.5 sm:gap-3 pb-4 sm:pb-6 border-b border-black/[0.06] dark:border-white/[0.06]">
            <span className="text-[11px] sm:text-xs font-mono uppercase tracking-wider text-zinc-500 dark:text-ink-muted">
              Select Document Source:
            </span>
            <div className="flex flex-wrap gap-1.5 sm:gap-2 w-full sm:w-auto relative">
              {EXCERPTS.map((e) => {
                const active = e.id === selectedExcerpt.id;
                return (
                  <button
                    key={e.id}
                    onClick={() => {
                      stopAudio();
                      setSelectedExcerpt(e);
                    }}
                    className={`relative rounded-lg px-2.5 sm:px-3.5 py-1 sm:py-1.5 text-xs font-medium transition-colors z-10 flex-1 sm:flex-initial text-center ${
                      active ? "text-[#0F9B51] dark:text-emerald font-semibold" : "text-zinc-600 dark:text-ink-secondary hover:text-zinc-900 dark:hover:text-white"
                    }`}
                  >
                    {active && (
                      <motion.div
                        layoutId="activeExcerptPill"
                        className="absolute inset-0 rounded-lg bg-[#E8EFE8] dark:bg-[#1C2520] border border-[#0F9B51]/30 dark:border-emerald/40 -z-10 shadow-sm"
                        transition={{ type: "spring", stiffness: 380, damping: 28 }}
                      />
                    )}
                    {e.title}
                  </button>
                );
              })}
            </div>
          </div>

          {/* Voice Engine Picker with animated card borders */}
          <div className="mt-4 sm:mt-6">
            <span className="text-[11px] sm:text-xs font-mono uppercase tracking-wider text-zinc-500 dark:text-ink-muted block mb-2 sm:mb-3">
              Voice Engine & Model:
            </span>
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-2.5 sm:gap-3">
              {VOICES.map((v) => {
                const active = v.id === selectedVoice.id;
                return (
                  <motion.button
                    key={v.id}
                    whileHover={{ y: -2 }}
                    whileTap={{ scale: 0.98 }}
                    onClick={() => {
                      stopAudio();
                      setSelectedVoice(v);
                    }}
                    className={`relative rounded-xl p-3 sm:p-3.5 text-left transition-all border ${
                      active
                        ? "bg-[#EBF2EB] dark:bg-[#18211B] border-[#0F9B51] dark:border-emerald text-zinc-900 dark:text-white shadow-md shadow-emerald/5"
                        : "bg-[#F8FAF8] dark:bg-[#141A16] border-black/[0.06] dark:border-white/5 text-zinc-600 dark:text-ink-secondary hover:border-black/15 dark:hover:border-white/15"
                    }`}
                  >
                    <div className="flex items-center justify-between mb-1 sm:mb-1.5">
                      <span className="text-xs font-bold text-zinc-900 dark:text-white">{v.name}</span>
                      <span
                        className={`text-[9px] sm:text-[10px] font-mono px-2 py-0.5 rounded ${
                          active
                            ? "bg-emerald/20 text-[#0F9B51] dark:text-emerald font-semibold"
                            : "bg-black/[0.04] dark:bg-[#1B231E] text-zinc-500 dark:text-ink-muted"
                        }`}
                      >
                        {v.tag}
                      </span>
                    </div>
                    <p className="text-[10px] sm:text-[11px] text-zinc-500 dark:text-ink-muted leading-relaxed line-clamp-2">
                      {v.description}
                    </p>
                  </motion.button>
                );
              })}
            </div>
          </div>

          {/* Spoken Excerpt Box with cross-fade animation */}
          <div className="mt-5 sm:mt-7 rounded-xl border border-black/[0.06] dark:border-white/5 bg-[#F5F8F5] dark:bg-[#0D120F] p-4 sm:p-6 min-h-[110px] sm:min-h-[140px] flex flex-col justify-between transition-colors">
            <div className="flex flex-col xs:flex-row items-start xs:items-center justify-between gap-1 mb-2.5 sm:mb-3 text-[10px] sm:text-[11px] font-mono text-zinc-500 dark:text-ink-muted">
              <span>{selectedExcerpt.category} · {selectedExcerpt.author}</span>
              <span className="text-[#0F9B51] dark:text-emerald flex items-center gap-1.5">
                <span className={`h-1.5 w-1.5 rounded-full bg-emerald ${isPlaying ? "animate-ping" : ""}`} />
                Live Transcript Preview
              </span>
            </div>

            <AnimatePresence mode="wait">
              <motion.p
                key={selectedExcerpt.id}
                initial={{ opacity: 0, y: 6 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -6 }}
                transition={{ duration: 0.25 }}
                className="text-xs sm:text-base font-serif italic text-zinc-800 dark:text-white/90 leading-relaxed"
              >
                &ldquo;{selectedExcerpt.text}&rdquo;
              </motion.p>
            </AnimatePresence>
          </div>

          {/* Controls bar with Reactive Waveform */}
          <div className="mt-5 sm:mt-7 pt-4 sm:pt-5 border-t border-black/[0.06] dark:border-white/[0.06] flex flex-col md:flex-row items-center justify-between gap-4 sm:gap-5">
            {/* Play Button & Title */}
            <div className="flex items-center gap-3 w-full sm:w-auto">
              <motion.button
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
                onClick={togglePlay}
                className="flex h-10 w-10 sm:h-12 sm:w-12 shrink-0 items-center justify-center rounded-xl bg-emerald text-black hover:bg-emerald-light transition-all shadow-md"
                aria-label={isPlaying ? "Pause" : "Play"}
              >
                {isPlaying ? <Pause className="h-4 w-4 sm:h-5 sm:w-5" /> : <Play className="h-4 w-4 sm:h-5 sm:w-5 ml-0.5" />}
              </motion.button>
              <div className="min-w-0">
                <p className="text-xs font-bold text-zinc-900 dark:text-white truncate">{selectedVoice.name}</p>
                <p className="text-[10px] sm:text-[11px] text-zinc-500 dark:text-ink-muted truncate">
                  {isPlaying ? "Streaming neural audio synthesis..." : "Tap play to test audio quality"}
                </p>
              </div>
            </div>

            {/* Live Waveform in center */}
            <div className="w-full sm:w-36 md:w-40 my-1 sm:my-0">
              <WaveformVisualizer isPlaying={isPlaying} barCount={22} height={24} />
            </div>

            {/* Speed Chips with spring transitions */}
            <div className="flex items-center justify-between sm:justify-start gap-1 sm:gap-1.5 rounded-lg border border-black/[0.06] dark:border-white/5 bg-[#EAEFEA] dark:bg-[#0D120F] p-1 w-full sm:w-auto">
              {[0.8, 1.0, 1.25, 1.5].map((s) => (
                <button
                  key={s}
                  onClick={() => {
                    setSpeed(s);
                    if (isPlaying) stopAudio();
                  }}
                  className={`rounded px-2 sm:px-2.5 py-1 font-mono text-[10px] sm:text-[11px] transition-all flex-1 sm:flex-initial text-center ${
                    speed === s
                      ? "bg-emerald text-black font-bold shadow-sm"
                      : "text-zinc-600 dark:text-ink-secondary hover:text-zinc-900 dark:hover:text-white"
                  }`}
                >
                  {s}x
                </button>
              ))}
            </div>

            {/* Scrub Bar */}
            <div className="w-full sm:w-36 bg-[#E2E8E2] dark:bg-[#1B231E] h-2 rounded-full overflow-hidden border border-black/[0.04] dark:border-white/5">
              <motion.div
                className="bg-emerald h-full"
                animate={{ width: `${progress}%` }}
                transition={{ duration: 0.2 }}
              />
            </div>
          </div>
        </motion.div>
      </div>
    </section>
  );
};
