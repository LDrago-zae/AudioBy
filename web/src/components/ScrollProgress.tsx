"use client";

import React, { useEffect, useRef } from "react";
import { animate, onScroll } from "animejs";

/** Full-page scroll progress bar driven by anime.js onScroll sync. */
export const ScrollProgress: React.FC = () => {
  const ref = useRef<HTMLDivElement | null>(null);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;

    const anim = animate(el, {
      scaleX: [0, 1],
      ease: "linear",
      autoplay: onScroll({
        target: document.documentElement,
        enter: "top top",
        leave: "bottom bottom",
        sync: true,
      }),
    });

    return () => {
      anim.pause();
      anim.revert?.();
    };
  }, []);

  return (
    <div
      className="fixed top-0 left-0 right-0 z-[60] h-[2px] origin-left pointer-events-none"
      aria-hidden
    >
      <div
        ref={ref}
        className="h-full w-full bg-emerald origin-left"
        style={{ transform: "scaleX(0)" }}
      />
    </div>
  );
};
