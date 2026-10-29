"use client";

import React, { useEffect, useState } from "react";
import { useScrollReveal } from "@/lib/anime-motion";

interface CounterProps {
  target: number;
  suffix?: string;
  prefix?: string;
}

const AnimatedCounter: React.FC<CounterProps> = ({ target, suffix = "", prefix = "" }) => {
  const [count, setCount] = useState(0);
  const ref = React.useRef<HTMLSpanElement>(null);
  const [started, setStarted] = useState(false);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    const io = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) setStarted(true);
      },
      { threshold: 0.4 }
    );
    io.observe(el);
    return () => io.disconnect();
  }, []);

  useEffect(() => {
    if (!started) return;
    let startTime: number;
    const duration = 1600;
    const step = (timestamp: number) => {
      if (!startTime) startTime = timestamp;
      const progress = Math.min((timestamp - startTime) / duration, 1);
      const ease = progress === 1 ? 1 : 1 - Math.pow(2, -10 * progress);
      setCount(Math.floor(ease * target));
      if (progress < 1) requestAnimationFrame(step);
    };
    requestAnimationFrame(step);
  }, [started, target]);

  return (
    <span ref={ref} className="tabular-nums">
      {prefix}
      {count.toLocaleString()}
      {suffix}
    </span>
  );
};

const STATS = [
  {
    value: <AnimatedCounter target={70000} suffix="+" />,
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
  const ref = useScrollReveal<HTMLElement>();

  return (
    <section
      ref={ref}
      className="border-y border-[var(--border-subtle)] bg-leaf-surface paper-grain relative overflow-hidden"
    >
      <div className="mx-auto max-w-6xl px-4 sm:px-6 py-12 sm:py-16">
        <h2
          data-reveal
          className="font-display text-2xl sm:text-3xl font-bold tracking-tight text-leaf-ink max-w-xl"
        >
          Built for long listening, not ten-minute demos.
        </h2>

        <div className="mt-10 grid grid-cols-2 md:grid-cols-4 gap-8 md:gap-6">
          {STATS.map((stat) => (
            <div key={stat.label} data-reveal className="flex flex-col">
              <span className="font-display text-2xl sm:text-3xl md:text-4xl font-bold tracking-tight text-leaf-ink">
                {stat.value}
              </span>
              <span className="mt-2 text-sm font-semibold text-leaf-ink">{stat.label}</span>
              <span className="mt-1 text-xs text-leaf-muted leading-relaxed">{stat.detail}</span>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
};
