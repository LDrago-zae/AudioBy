"use client";

import React, { useState, useEffect } from "react";
import { motion, AnimatePresence } from "motion/react";
import { Play, Pause, ArrowRight } from "lucide-react";
import { WaveformVisualizer } from "./WaveformVisualizer";

interface FloatingPlayerDockProps {
  onUpgrade: () => void;
}

export const FloatingPlayerDock: React.FC<FloatingPlayerDockProps> = ({ onUpgrade }) => {
  const [visible, setVisible] = useState(false);
  const [isPlaying, setIsPlaying] = useState(false);
  const [speed, setSpeed] = useState(1.0);

  useEffect(() => {
    const handleScroll = () => {
      if (window.scrollY > 400) {
        setVisible(true);
      } else {
        setVisible(false);
      }
    };

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
    const next = speeds[(speeds.indexOf(speed) + 1) % speeds.length];
    setSpeed(next);
  };

  return (
    <AnimatePresence>
      {visible && (
        <motion.div
          initial={{ y: 100, opacity: 0, scale: 0.95 }}
          animate={{ y: 0, opacity: 1, scale: 1 }}
          exit={{ y: 100, opacity: 0, scale: 0.95 }}
          transition={{ type: "spring", damping: 22, stiffness: 260 }}
          className="fixed bottom-3 sm:bottom-6 left-1/2 -translate-x-1/2 z-40 w-[95%] sm:w-[94%] max-w-xl pb-[env(safe-area-inset-bottom)]"
        >
          <div className="flex items-center justify-between gap-2 sm:gap-3 rounded-2xl border border-black/10 dark:border-white/15 bg-white/95 dark:bg-[#121714]/95 p-2 sm:p-3 shadow-2xl backdrop-blur-xl transition-colors duration-200">
            {/* Play Button & Title */}
            <div className="flex items-center gap-2.5 sm:gap-3 min-w-0">
              <motion.button
                whileTap={{ scale: 0.92 }}
                onClick={toggleAudio}
                className="flex h-9 w-9 sm:h-10 sm:w-10 shrink-0 items-center justify-center rounded-xl bg-emerald text-black shadow-md hover:bg-emerald-light transition-colors"
                aria-label={isPlaying ? "Pause audio" : "Play audio"}
              >
                {isPlaying ? <Pause className="h-4 w-4" /> : <Play className="h-4 w-4 ml-0.5" />}
              </motion.button>

              <div className="min-w-0">
                <div className="flex items-center gap-1.5 sm:gap-2">
                  <p className="text-[11px] sm:text-xs font-bold text-zinc-900 dark:text-white truncate max-w-[120px] xs:max-w-[170px] sm:max-w-none">
                    Dorian Gray · Ch. 1
                  </p>
                  <span className="hidden sm:inline-flex items-center gap-1 text-[9px] font-mono text-[#0F9B51] dark:text-emerald px-1.5 py-0.5 rounded bg-emerald/10 border border-emerald/20">
                    <span className="h-1 w-1 rounded-full bg-emerald animate-pulse" />
                    ElevenLabs
                  </span>
                </div>
                <p className="text-[9px] sm:text-[10px] text-zinc-500 dark:text-ink-muted truncate max-w-[120px] xs:max-w-[170px] sm:max-w-none">
                  {isPlaying ? "Playing sample voice..." : "Click to test anywhere"}
                </p>
              </div>
            </div>

            {/* Mini Waveform */}
            <div className="hidden md:block w-24 shrink-0">
              <WaveformVisualizer isPlaying={isPlaying} barCount={18} height={22} />
            </div>

            {/* Speed pill & Upgrade button */}
            <div className="flex items-center gap-1.5 sm:gap-2 shrink-0">
              <button
                onClick={cycleSpeed}
                title="Playback Speed"
                className="rounded-lg border border-black/[0.08] dark:border-white/10 bg-black/[0.03] dark:bg-[#161D19] px-2 py-1 text-[10px] sm:text-[11px] font-mono font-bold text-zinc-800 dark:text-ink-primary hover:text-zinc-900 dark:hover:text-white hover:border-black/20 dark:hover:border-white/20 transition-colors"
              >
                {speed}x
              </button>

              <motion.button
                whileHover={{ scale: 1.03 }}
                whileTap={{ scale: 0.97 }}
                onClick={onUpgrade}
                className="flex items-center gap-1 rounded-xl bg-emerald px-2.5 py-1 sm:px-3 sm:py-1.5 text-[11px] sm:text-xs font-bold text-black hover:bg-emerald-light transition-colors shadow-md"
              >
                <span>Upgrade</span>
                <ArrowRight className="h-3 w-3" />
              </motion.button>
            </div>
          </div>
        </motion.div>
      )}
    </AnimatePresence>
  );
};
