"use client";

import React, { useEffect, useState } from "react";
import { motion, useInView } from "motion/react";

interface CounterProps {
  target: number;
  suffix?: string;
  prefix?: string;
}

const AnimatedCounter: React.FC<CounterProps> = ({ target, suffix = "", prefix = "" }) => {
  const [count, setCount] = useState(0);
  const ref = React.useRef(null);
  const isInView = useInView(ref, { once: true, margin: "-50px" });

  useEffect(() => {
    if (!isInView) return;

    let startTime: number;
    const duration = 1600;

    const step = (timestamp: number) => {
      if (!startTime) startTime = timestamp;
      const progress = Math.min((timestamp - startTime) / duration, 1);
      const ease = progress === 1 ? 1 : 1 - Math.pow(2, -10 * progress);
      setCount(Math.floor(ease * target));

      if (progress < 1) {
        requestAnimationFrame(step);
      }
    };

    requestAnimationFrame(step);
  }, [isInView, target]);

  return (
    <span ref={ref} className="font-mono">
      {prefix}
      {count.toLocaleString()}
      {suffix}
    </span>
  );
};

export const ProofStrip: React.FC = () => {
  return (
    <section className="border-y border-black/[0.08] dark:border-white/[0.08] bg-zinc-100/70 dark:bg-[#0B0D11] relative overflow-hidden transition-colors duration-200">
      <div className="mx-auto max-w-6xl px-3.5 sm:px-6 py-8 sm:py-10">
        <div className="flex items-center gap-2 mb-6 sm:mb-8 text-[11px] font-mono tracking-wider uppercase text-zinc-500 dark:text-zinc-400">
          <span className="font-bold text-[#059669] dark:text-[#10B981]">[ 01 ]</span>
          <span className="font-semibold text-zinc-700 dark:text-zinc-300">BENCHMARKED STANDARDS · ZERO COMPROMISE</span>
        </div>

        <div className="grid grid-cols-2 md:grid-cols-4 gap-6 sm:gap-8 divide-y sm:divide-y-0 md:divide-x divide-black/[0.06] dark:divide-white/[0.06]">
          <motion.div
            initial={{ opacity: 0, y: 16 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.5, delay: 0.05 }}
            className="flex flex-col pt-3 sm:pt-0 md:px-4 first:px-0"
          >
            <span className="text-2xl sm:text-3xl md:text-4xl font-bold tracking-tight text-zinc-950 dark:text-white font-mono">
              <AnimatedCounter target={70000} suffix="+" />
            </span>
            <span className="mt-1.5 text-xs sm:text-sm font-semibold text-zinc-900 dark:text-zinc-200">
              Curated public classics
            </span>
            <span className="text-[11px] text-zinc-500 dark:text-zinc-400 leading-normal mt-0.5">
              Available instantly without paywalls via Gutenberg
            </span>
          </motion.div>

          <motion.div
            initial={{ opacity: 0, y: 16 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.5, delay: 0.15 }}
            className="flex flex-col pt-3 sm:pt-0 md:px-4"
          >
            <span className="text-2xl sm:text-3xl md:text-4xl font-bold tracking-tight text-zinc-950 dark:text-white font-mono">
              0 bytes
            </span>
            <span className="mt-1.5 text-xs sm:text-sm font-semibold text-zinc-900 dark:text-zinc-200">
              Leave your device
            </span>
            <span className="text-[11px] text-zinc-500 dark:text-zinc-400 leading-normal mt-0.5">
              Private on-device neural synthesis option
            </span>
          </motion.div>

          <motion.div
            initial={{ opacity: 0, y: 16 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.5, delay: 0.25 }}
            className="flex flex-col pt-3 sm:pt-0 md:px-4"
          >
            <span className="text-2xl sm:text-3xl md:text-4xl font-bold tracking-tight text-zinc-950 dark:text-white font-mono">
              &lt; 500 ms
            </span>
            <span className="mt-1.5 text-xs sm:text-sm font-semibold text-zinc-900 dark:text-zinc-200">
              First syllable latency
            </span>
            <span className="text-[11px] text-zinc-500 dark:text-zinc-400 leading-normal mt-0.5">
              Immediate audio feedback from cold start
            </span>
          </motion.div>

          <motion.div
            initial={{ opacity: 0, y: 16 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.5, delay: 0.35 }}
            className="flex flex-col pt-3 sm:pt-0 md:px-4"
          >
            <span className="text-2xl sm:text-3xl md:text-4xl font-bold tracking-tight text-zinc-950 dark:text-white font-mono">
              100%
            </span>
            <span className="mt-1.5 text-xs sm:text-sm font-semibold text-zinc-900 dark:text-zinc-200">
              Offline cached playback
            </span>
            <span className="text-[11px] text-zinc-500 dark:text-zinc-400 leading-normal mt-0.5">
              Airplanes, subways, and remote wilderness
            </span>
          </motion.div>
        </div>
      </div>
    </section>
  );
};
