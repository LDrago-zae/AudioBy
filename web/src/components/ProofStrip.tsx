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
    <div className="border-y border-black/[0.08] dark:border-white/[0.08] bg-[#F1F5F2] dark:bg-[#0A0D0B] relative overflow-hidden transition-colors duration-200">
      <div className="mx-auto max-w-6xl px-3.5 sm:px-6 py-7 sm:py-10">
        <div className="flex items-center gap-2 mb-6 sm:mb-8 text-[10px] font-mono tracking-eyebrow uppercase text-[#0F9B51] dark:text-emerald">
          <span className="h-1.5 w-1.5 rounded-full bg-emerald animate-pulse" />
          <span>Day One, No Asterisk</span>
        </div>

        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 sm:gap-8">
          <motion.div
            initial={{ opacity: 0, y: 16 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.5, delay: 0.05 }}
            className="flex flex-col"
          >
            <span className="text-2xl sm:text-3xl md:text-4xl font-bold tracking-tight text-zinc-900 dark:text-white font-mono">
              <AnimatedCounter target={70000} suffix="+" />
            </span>
            <span className="mt-1 text-xs font-semibold text-zinc-800 dark:text-ink-primary">
              Public domain books
            </span>
            <span className="text-[10px] sm:text-[11px] text-zinc-500 dark:text-ink-muted leading-tight mt-0.5">
              Free forever via Project Gutenberg
            </span>
          </motion.div>

          <motion.div
            initial={{ opacity: 0, y: 16 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.5, delay: 0.15 }}
            className="flex flex-col"
          >
            <span className="text-2xl sm:text-3xl md:text-4xl font-bold tracking-tight text-zinc-900 dark:text-white font-mono">
              0 bytes
            </span>
            <span className="mt-1 text-xs font-semibold text-zinc-800 dark:text-ink-primary">
              Leave your device
            </span>
            <span className="text-[10px] sm:text-[11px] text-zinc-500 dark:text-ink-muted leading-tight mt-0.5">
              Private on-device neural synthesis
            </span>
          </motion.div>

          <motion.div
            initial={{ opacity: 0, y: 16 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.5, delay: 0.25 }}
            className="flex flex-col"
          >
            <span className="text-2xl sm:text-3xl md:text-4xl font-bold tracking-tight text-zinc-900 dark:text-white font-mono">
              <AnimatedCounter target={100} suffix="%" />
            </span>
            <span className="mt-1 text-xs font-semibold text-zinc-800 dark:text-ink-primary">
              Offline caching
            </span>
            <span className="text-[10px] sm:text-[11px] text-zinc-500 dark:text-ink-muted leading-tight mt-0.5">
              Play on flights with zero cellular
            </span>
          </motion.div>

          <motion.div
            initial={{ opacity: 0, y: 16 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.5, delay: 0.35 }}
            className="flex flex-col"
          >
            <span className="text-2xl sm:text-3xl md:text-4xl font-bold tracking-tight text-zinc-900 dark:text-white font-mono">
              1 sub
            </span>
            <span className="mt-1 text-xs font-semibold text-zinc-800 dark:text-ink-primary">
              Universal access
            </span>
            <span className="text-[10px] sm:text-[11px] text-zinc-500 dark:text-ink-muted leading-tight mt-0.5">
              Seamless sync across iOS and Web
            </span>
          </motion.div>
        </div>
      </div>
    </div>
  );
};
