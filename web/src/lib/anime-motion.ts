"use client";

import { useEffect, useRef } from "react";
import {
  animate,
  createTimeline,
  onScroll,
  splitText,
  stagger,
  type JSAnimation,
  type Timeline,
} from "animejs";

const EASE_OUT = "outExpo";

/** Scroll-triggered stagger reveal for `[data-reveal]` children. */
export function useScrollReveal<T extends HTMLElement = HTMLElement>() {
  const ref = useRef<T | null>(null);

  useEffect(() => {
    const root = ref.current;
    if (!root) return;

    const targets = root.querySelectorAll<HTMLElement>("[data-reveal]");
    if (!targets.length) return;

    targets.forEach((el) => {
      el.style.opacity = "0";
      el.style.transform = "translateY(28px)";
      el.style.filter = "blur(6px)";
    });

    const animation = animate(targets, {
      opacity: [0, 1],
      y: [28, 0],
      filter: ["blur(6px)", "blur(0px)"],
      ease: EASE_OUT,
      duration: 880,
      delay: stagger(70, { start: 40 }),
      autoplay: onScroll({
        target: root,
        enter: "bottom-=12% top",
        leave: "top+=10% bottom",
        repeat: false,
      }),
    });

    return () => {
      animation.pause();
      animation.revert?.();
    };
  }, []);

  return ref;
}

/** Hero entrance: brand chars, then copy, CTAs, player. */
export function useHeroEntrance(ready = true) {
  const rootRef = useRef<HTMLElement | null>(null);

  useEffect(() => {
    if (!ready) return;
    const root = rootRef.current;
    if (!root) return;

    const brand = root.querySelector<HTMLElement>("[data-hero-brand]");
    const lines = root.querySelectorAll<HTMLElement>("[data-hero-line]");
    const ctas = root.querySelectorAll<HTMLElement>("[data-hero-cta]");
    const player = root.querySelector<HTMLElement>("[data-hero-player]");
    const bars = root.querySelectorAll<HTMLElement>("[data-hero-bar]");

    let split: ReturnType<typeof splitText> | null = null;
    let timeline: Timeline | null = null;
    let barLoop: JSAnimation | null = null;

    if (brand) {
      split = splitText(brand, {
        chars: { wrap: "clip", class: "hero-char" },
        accessible: true,
      });
    }

    const chars = root.querySelectorAll(".hero-char");

    timeline = createTimeline({ defaults: { ease: EASE_OUT } });

    if (chars.length) {
      timeline.add(chars, {
        y: ["110%", "0%"],
        opacity: [0, 1],
        duration: 780,
        delay: stagger(28),
      });
    }

    if (lines.length) {
      timeline.add(
        lines,
        {
          opacity: [0, 1],
          y: [22, 0],
          filter: ["blur(8px)", "blur(0px)"],
          duration: 720,
          delay: stagger(90),
        },
        "-=420"
      );
    }

    if (ctas.length) {
      timeline.add(
        ctas,
        {
          opacity: [0, 1],
          y: [16, 0],
          duration: 560,
          delay: stagger(70),
        },
        "-=380"
      );
    }

    if (player) {
      timeline.add(
        player,
        {
          opacity: [0, 1],
          y: [36, 0],
          scale: [0.97, 1],
          duration: 900,
        },
        "-=280"
      );
    }

    if (bars.length) {
      barLoop = animate(bars, {
        scaleY: stagger([0.35, 1.05], { from: "center" }),
        opacity: stagger([0.35, 0.95], { from: "center" }),
        duration: 1600,
        ease: "inOutSine",
        loop: true,
        alternate: true,
        delay: stagger(28, { from: "center" }),
      });
    }

    return () => {
      timeline?.pause();
      barLoop?.pause();
      split?.revert?.();
    };
  }, [ready]);

  return rootRef;
}

/** Soft pulse on interactive controls via anime.js. */
export function pulseTap(el: HTMLElement | null) {
  if (!el) return;
  animate(el, {
    scale: [1, 0.96, 1],
    duration: 280,
    ease: "outQuad",
  });
}
