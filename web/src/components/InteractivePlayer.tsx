"use client";

import React, { useState, useEffect, useRef } from "react";
import { Play, Pause } from "lucide-react";
import { WaveformVisualizer } from "./WaveformVisualizer";
import { pulseTap, useScrollReveal } from "@/lib/anime-motion";

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
    description: "Deep, resonant tone with natural breathing cadence for narrative fiction.",
    rate: 0.95,
    pitch: 0.9,
  },
  {
    id: "rachel",
    name: "ElevenLabs Rachel",
    tag: "Studio Warmth",
    description: "Nuanced conversational rhythm for essays, reports, and long academic papers.",
    rate: 1.0,
    pitch: 1.05,
  },
  {
    id: "device",
    name: "On-Device Neural",
    tag: "0ms Offline",
    description: "Synthesized on your local device. Instant start, zero network overhead.",
    rate: 1.05,
    pitch: 1.0,
  },
];

export const InteractivePlayer: React.FC = () => {
  const [selectedExcerpt, setSelectedExcerpt] = useState<Excerpt>(EXCERPTS[0]);
  const [selectedVoice, setSelectedVoice] = useState<Voice>(VOICES[0]);
  const [speed, setSpeed] = useState<number>(1.0);
  const [isPlaying, setIsPlaying] = useState(false);
  const [progress, setProgress] = useState(0);
  const synthRef = useRef<SpeechSynthesis | null>(null);
  const ref = useScrollReveal<HTMLElement>();

  useEffect(() => {
    if (typeof window !== "undefined" && "speechSynthesis" in window) {
      synthRef.current = window.speechSynthesis;
    }
    return () => {
      synthRef.current?.cancel();
    };
  }, []);

  const stopAudio = () => {
    synthRef.current?.cancel();
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
    <section
      id="lab"
      ref={ref}
      className="py-20 sm:py-28 border-t border-[var(--border-subtle)] bg-leaf-surface paper-grain"
    >
      <div className="mx-auto max-w-5xl px-4 sm:px-6">
        <div className="max-w-2xl">
          <h2
            data-reveal
            className="font-display text-3xl sm:text-5xl font-bold tracking-tight text-leaf-ink leading-[1.08]"
          >
            Hear before you sign up.
          </h2>
          <p data-reveal className="mt-4 text-sm sm:text-base text-leaf-muted max-w-measure leading-relaxed">
            Switch document sources and neural voices to audit cadence, warmth, and latency.
          </p>
        </div>

        <div
          data-reveal
          className="mt-12 sm:mt-14 rounded-2xl border border-[var(--border-subtle)] bg-leaf-raised p-4 sm:p-8 shadow-soft"
        >
          <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3 pb-5 border-b border-[var(--border-subtle)]">
            <span className="text-xs font-semibold text-leaf-faint uppercase tracking-wide">
              Source
            </span>
            <div className="flex flex-wrap gap-2 w-full sm:w-auto">
              {EXCERPTS.map((e) => {
                const active = e.id === selectedExcerpt.id;
                return (
                  <button
                    key={e.id}
                    type="button"
                    onClick={() => {
                      stopAudio();
                      setSelectedExcerpt(e);
                    }}
                    className={`rounded-lg px-3 py-1.5 text-xs font-semibold transition-colors flex-1 sm:flex-initial ${
                      active
                        ? "bg-emerald text-emerald-ink"
                        : "bg-leaf-surface text-leaf-muted hover:text-leaf-ink border border-[var(--border-subtle)]"
                    }`}
                  >
                    {e.title}
                  </button>
                );
              })}
            </div>
          </div>

          <div className="mt-5">
            <span className="text-xs font-semibold text-leaf-faint uppercase tracking-wide block mb-3">
              Voice
            </span>
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
              {VOICES.map((v) => {
                const active = v.id === selectedVoice.id;
                return (
                  <button
                    key={v.id}
                    type="button"
                    onClick={() => {
                      stopAudio();
                      setSelectedVoice(v);
                    }}
                    className={`rounded-xl p-4 text-left transition-all border ${
                      active
                        ? "bg-leaf-surface border-emerald-dark dark:border-emerald text-leaf-ink shadow-soft"
                        : "bg-leaf-surface/50 border-[var(--border-subtle)] text-leaf-muted hover:border-emerald/40"
                    }`}
                  >
                    <div className="flex items-center justify-between mb-1.5 gap-2">
                      <span className="text-xs font-bold text-leaf-ink">{v.name}</span>
                      <span
                        className={`text-[10px] px-2 py-0.5 rounded-md shrink-0 ${
                          active
                            ? "bg-emerald/15 text-emerald-dark dark:text-emerald font-semibold border border-emerald/30"
                            : "bg-black/5 dark:bg-white/5 text-leaf-faint"
                        }`}
                      >
                        {v.tag}
                      </span>
                    </div>
                    <p className="text-[11px] text-leaf-muted leading-relaxed line-clamp-2">
                      {v.description}
                    </p>
                  </button>
                );
              })}
            </div>
          </div>

          <div className="mt-6 rounded-xl border border-[var(--border-subtle)] bg-leaf-surface p-4 sm:p-6 min-h-[120px]">
            <div className="flex flex-col xs:flex-row items-start xs:items-center justify-between gap-1 mb-3 text-[11px] text-leaf-faint">
              <span>
                {selectedExcerpt.category} · {selectedExcerpt.author}
              </span>
              <span className="text-emerald-dark dark:text-emerald flex items-center gap-1.5 font-semibold">
                <span className={`h-1.5 w-1.5 rounded-full bg-emerald ${isPlaying ? "animate-pulse" : ""}`} />
                {isPlaying ? "Rendering" : "Sample"}
              </span>
            </div>
            <p className="font-display text-base sm:text-lg italic text-leaf-ink leading-relaxed">
              &ldquo;{selectedExcerpt.text}&rdquo;
            </p>
          </div>

          <div className="mt-6 pt-5 border-t border-[var(--border-subtle)] flex flex-col md:flex-row items-center justify-between gap-4">
            <div className="flex items-center gap-3 w-full sm:w-auto">
              <button
                type="button"
                onClick={(e) => {
                  pulseTap(e.currentTarget);
                  togglePlay();
                }}
                className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl bg-emerald text-emerald-ink hover:bg-emerald-dark dark:hover:bg-emerald-light transition-colors"
                aria-label={isPlaying ? "Pause" : "Play"}
              >
                {isPlaying ? <Pause className="h-4 w-4" /> : <Play className="h-4 w-4 ml-0.5" />}
              </button>
              <div className="min-w-0">
                <p className="text-xs font-bold text-leaf-ink truncate">{selectedVoice.name}</p>
                <p className="text-[11px] text-leaf-faint truncate">
                  {isPlaying ? "Streaming neural audio…" : "Tap play to test cadence"}
                </p>
              </div>
            </div>

            <div className="w-full sm:w-40">
              <WaveformVisualizer isPlaying={isPlaying} barCount={24} height={24} />
            </div>

            <div className="flex items-center gap-1 rounded-lg border border-[var(--border-subtle)] bg-leaf-surface p-1 w-full sm:w-auto">
              {[0.8, 1.0, 1.25, 1.5].map((s) => (
                <button
                  key={s}
                  type="button"
                  onClick={() => {
                    setSpeed(s);
                    if (isPlaying) stopAudio();
                  }}
                  className={`rounded-md px-2.5 py-1 text-[11px] transition-all flex-1 sm:flex-initial tabular-nums ${
                    speed === s
                      ? "bg-emerald text-emerald-ink font-bold"
                      : "text-leaf-muted hover:text-leaf-ink"
                  }`}
                >
                  {s}x
                </button>
              ))}
            </div>

            <div className="w-full sm:w-36 bg-black/10 dark:bg-white/10 h-2 rounded-full overflow-hidden">
              <div
                className="bg-emerald h-full transition-[width] duration-200"
                style={{ width: `${progress}%` }}
              />
            </div>
          </div>
        </div>
      </div>
    </section>
  );
};
