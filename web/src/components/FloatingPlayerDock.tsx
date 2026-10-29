"use client";

import React, { useState, useEffect } from "react";
import { Play, Pause, ArrowRight } from "lucide-react";
import { WaveformVisualizer } from "./WaveformVisualizer";
import { pulseTap, useDockMotion } from "@/lib/anime-motion";

interface FloatingPlayerDockProps {
  onUpgrade: () => void;
}

export const FloatingPlayerDock: React.FC<FloatingPlayerDockProps> = ({ onUpgrade }) => {
  const [visible, setVisible] = useState(false);
  const [isPlaying, setIsPlaying] = useState(false);
  const [speed, setSpeed] = useState(1.0);
  const dockRef = useDockMotion(visible);

  useEffect(() => {
    const handleScroll = () => setVisible(window.scrollY > 400);
    handleScroll();
    window.addEventListener("scroll", handleScroll, { passive: true });
    return () => window.removeEventListener("scroll", handleScroll);
  }, []);

  const toggleAudio = () => {
    if (typeof window === "undefined" || !("speechSynthesis" in window)) {
      setIsPlaying(!isPlaying);
      return;
    }
    if (isPlaying) {
      window.speechSynthesis.cancel();
      setIsPlaying(false);
    } else {
      window.speechSynthesis.cancel();
      const u = new SpeechSynthesisUtterance(
        "AudioBy turns your documents and classic books into studio-quality audio, anywhere."
      );
      u.rate = speed;
      u.onend = () => setIsPlaying(false);
      u.onerror = () => setIsPlaying(false);
      window.speechSynthesis.speak(u);
      setIsPlaying(true);
    }
  };

  const cycleSpeed = () => {
    const speeds = [1.0, 1.25, 1.5, 2.0];
    setSpeed(speeds[(speeds.indexOf(speed) + 1) % speeds.length]);
  };

  return (
    <div
      ref={dockRef}
      className="fixed bottom-3 sm:bottom-6 left-1/2 -translate-x-1/2 z-40 w-[95%] sm:w-[94%] max-w-xl pb-[env(safe-area-inset-bottom)] opacity-0 pointer-events-none"
      style={{ willChange: "transform, opacity" }}
    >
      <div className="flex items-center justify-between gap-2 sm:gap-3 rounded-2xl border border-[var(--border-subtle)] bg-leaf-raised/95 p-2 sm:p-3 shadow-lift backdrop-blur-md">
        <div className="flex items-center gap-2.5 sm:gap-3 min-w-0">
          <button
            type="button"
            onClick={(e) => {
              pulseTap(e.currentTarget);
              toggleAudio();
            }}
            className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-emerald text-emerald-ink hover:bg-emerald-dark dark:hover:bg-emerald-light transition-colors"
            aria-label={isPlaying ? "Pause audio" : "Play audio"}
          >
            {isPlaying ? <Pause className="h-4 w-4" /> : <Play className="h-4 w-4 ml-0.5" />}
          </button>

          <div className="min-w-0">
            <div className="flex items-center gap-2">
              <p className="text-xs font-bold text-leaf-ink truncate max-w-[140px] sm:max-w-none font-display">
                Dorian Gray · Ch. 1
              </p>
              <span className="hidden sm:inline-flex items-center gap-1 text-[9px] text-emerald-dark dark:text-emerald px-1.5 py-0.5 rounded-md bg-emerald/10 border border-emerald/20 font-semibold">
                ElevenLabs
              </span>
            </div>
            <p className="text-[10px] text-leaf-faint truncate">
              {isPlaying ? "Rendering acoustic synthesis…" : "Click to test sample voice"}
            </p>
          </div>
        </div>

        <div className="hidden md:block w-24 shrink-0">
          <WaveformVisualizer isPlaying={isPlaying} barCount={18} height={22} />
        </div>

        <div className="flex items-center gap-1.5 sm:gap-2 shrink-0">
          <button
            type="button"
            onClick={cycleSpeed}
            title="Playback Speed"
            className="rounded-lg border border-[var(--border-subtle)] bg-leaf-surface px-2 py-1 text-[11px] font-bold text-leaf-ink tabular-nums"
          >
            {speed}x
          </button>

          <button
            type="button"
            onClick={(e) => {
              pulseTap(e.currentTarget);
              onUpgrade();
            }}
            className="flex items-center gap-1 rounded-xl bg-emerald px-3 py-1.5 text-xs font-bold text-emerald-ink hover:bg-emerald-dark dark:hover:bg-emerald-light transition-colors"
          >
            Upgrade
            <ArrowRight className="h-3 w-3" />
          </button>
        </div>
      </div>
    </div>
  );
};
