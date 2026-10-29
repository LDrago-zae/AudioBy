"use client";

import { useEffect, useRef } from "react";
import {
  animate,
  createAnimatable,
  createDrawable,
  createDraggable,
  createScope,
  createSpring,
  createTimeline,
  onScroll,
  scrambleText,
  splitText,
  stagger,
  type JSAnimation,
  type Timeline,
} from "animejs";

const EASE_OUT = "outExpo";

function prefersReducedMotion() {
  if (typeof window === "undefined") return false;
  return window.matchMedia("(prefers-reduced-motion: reduce)").matches;
}

/** Scroll-triggered stagger reveal for `[data-reveal]` children. */
export function useScrollReveal<T extends HTMLElement = HTMLElement>(opts?: {
  y?: number;
  blur?: number;
  staggerMs?: number;
}) {
  const ref = useRef<T | null>(null);
  const y = opts?.y ?? 32;
  const blur = opts?.blur ?? 8;
  const staggerMs = opts?.staggerMs ?? 80;

  useEffect(() => {
    const root = ref.current;
    if (!root) return;
    if (prefersReducedMotion()) {
      root.querySelectorAll<HTMLElement>("[data-reveal]").forEach((el) => {
        el.style.opacity = "1";
        el.style.transform = "none";
        el.style.filter = "none";
      });
      return;
    }

    const targets = root.querySelectorAll<HTMLElement>("[data-reveal]");
    if (!targets.length) return;

    targets.forEach((el) => {
      el.style.opacity = "0";
      el.style.transform = `translateY(${y}px)`;
      el.style.filter = `blur(${blur}px)`;
    });

    const animation = animate(targets, {
      opacity: [0, 1],
      y: [y, 0],
      filter: [`blur(${blur}px)`, "blur(0px)"],
      ease: EASE_OUT,
      duration: 920,
      delay: stagger(staggerMs, { start: 40 }),
      autoplay: onScroll({
        target: root,
        enter: "bottom-=14% top",
        leave: "top+=8% bottom",
        repeat: false,
      }),
    });

    return () => {
      animation.pause();
      animation.revert?.();
    };
  }, [y, blur, staggerMs]);

  return ref;
}

/** Word-split heading entrance on `[data-split]`. */
export function useSplitHeading<T extends HTMLElement = HTMLElement>() {
  const ref = useRef<T | null>(null);

  useEffect(() => {
    const root = ref.current;
    if (!root || prefersReducedMotion()) return;

    const headings = root.querySelectorAll<HTMLElement>("[data-split]");
    if (!headings.length) return;

    const splits: Array<ReturnType<typeof splitText>> = [];
    const animations: JSAnimation[] = [];

    headings.forEach((heading) => {
      const split = splitText(heading, {
        words: { wrap: "clip", class: "split-word" },
        accessible: true,
      });
      splits.push(split);

      const words = heading.querySelectorAll(".split-word");
      words.forEach((w) => {
        (w as HTMLElement).style.opacity = "0";
        (w as HTMLElement).style.transform = "translateY(110%)";
      });

      const anim = animate(words, {
        y: ["110%", "0%"],
        opacity: [0, 1],
        ease: EASE_OUT,
        duration: 780,
        delay: stagger(48),
        autoplay: onScroll({
          target: heading,
          enter: "bottom-=10% top",
          repeat: false,
        }),
      });
      animations.push(anim);
    });

    return () => {
      animations.forEach((a) => {
        a.pause();
        a.revert?.();
      });
      splits.forEach((s) => s.revert?.());
    };
  }, []);

  return ref;
}

/** Scroll-synced progress for `[data-scroll-sync]` (parallax / draw / scrub). */
export function useScrollSync<T extends HTMLElement = HTMLElement>() {
  const ref = useRef<T | null>(null);

  useEffect(() => {
    const root = ref.current;
    if (!root || prefersReducedMotion()) return;

    const layers = root.querySelectorAll<HTMLElement>("[data-parallax]");
    const anims: JSAnimation[] = [];

    layers.forEach((layer) => {
      const speed = Number(layer.dataset.parallax || 40);
      const anim = animate(layer, {
        y: [`${speed}px`, `-${speed}px`],
        ease: "linear",
        autoplay: onScroll({
          target: root,
          enter: "top bottom",
          leave: "bottom top",
          sync: true,
        }),
      });
      anims.push(anim);
    });

    const paths = root.querySelectorAll("path[data-draw]");
    if (paths.length) {
      const drawables = createDrawable(paths);
      const drawAnim = animate(drawables, {
        draw: ["0 0", "0 1"],
        ease: "inOutCubic",
        autoplay: onScroll({
          target: root,
          enter: "top bottom",
          leave: "center top",
          sync: 0.35,
        }),
      });
      anims.push(drawAnim);
    }

    return () => {
      anims.forEach((a) => {
        a.pause();
        a.revert?.();
      });
    };
  }, []);

  return ref;
}

/** Anime.js number tween for counters (`data-count-to`). */
export function useAnimeCounter(target: number, suffix = "", prefix = "") {
  const ref = useRef<HTMLSpanElement | null>(null);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;

    if (prefersReducedMotion()) {
      el.textContent = `${prefix}${target.toLocaleString()}${suffix}`;
      return;
    }

    const state = { value: 0 };
    el.textContent = `${prefix}0${suffix}`;

    const anim = animate(state, {
      value: target,
      duration: 1600,
      ease: EASE_OUT,
      modifier: (v: number) => Math.round(v),
      onUpdate: () => {
        el.textContent = `${prefix}${Math.round(state.value).toLocaleString()}${suffix}`;
      },
      autoplay: onScroll({
        target: el,
        enter: "bottom-=20% top",
        repeat: false,
      }),
    });

    return () => {
      anim.pause();
      anim.revert?.();
    };
  }, [target, suffix, prefix]);

  return ref;
}

/** Magnetic hover via createAnimatable. */
export function useMagnetic<T extends HTMLElement = HTMLElement>(strength = 14) {
  const ref = useRef<T | null>(null);

  useEffect(() => {
    const el = ref.current;
    if (!el || prefersReducedMotion()) return;

    const spring = createSpring({ stiffness: 180, damping: 18 });
    const animatable = createAnimatable(el, {
      x: { ease: spring },
      y: { ease: spring },
    });

    const onMove = (e: PointerEvent) => {
      const rect = el.getBoundingClientRect();
      const cx = rect.left + rect.width / 2;
      const cy = rect.top + rect.height / 2;
      animatable.x((e.clientX - cx) / strength);
      animatable.y((e.clientY - cy) / strength);
    };
    const onLeave = () => {
      animatable.x(0);
      animatable.y(0);
    };

    el.addEventListener("pointermove", onMove);
    el.addEventListener("pointerleave", onLeave);
    return () => {
      el.removeEventListener("pointermove", onMove);
      el.removeEventListener("pointerleave", onLeave);
      animatable.revert?.();
    };
  }, [strength]);

  return ref;
}

/** Soft lift on hover for pricing / cards. */
export function useSpringHover<T extends HTMLElement = HTMLElement>() {
  const ref = useRef<T | null>(null);

  useEffect(() => {
    const root = ref.current;
    if (!root || prefersReducedMotion()) return;

    const cards = root.querySelectorAll<HTMLElement>("[data-spring-hover]");
    const cleanups: Array<() => void> = [];

    cards.forEach((card) => {
      const spring = createSpring({ stiffness: 220, damping: 16 });
      const animatable = createAnimatable(card, {
        y: { ease: spring },
        scale: { ease: spring },
      });
      const enter = () => {
        animatable.y(-6);
        animatable.scale(1.015);
      };
      const leave = () => {
        animatable.y(0);
        animatable.scale(1);
      };
      card.addEventListener("pointerenter", enter);
      card.addEventListener("pointerleave", leave);
      cleanups.push(() => {
        card.removeEventListener("pointerenter", enter);
        card.removeEventListener("pointerleave", leave);
        animatable.revert?.();
      });
    });

    return () => cleanups.forEach((fn) => fn());
  }, []);

  return ref;
}

/** Scramble text on hover for `[data-scramble]`. */
export function useScrambleHover<T extends HTMLElement = HTMLElement>() {
  const ref = useRef<T | null>(null);

  useEffect(() => {
    const root = ref.current;
    if (!root || prefersReducedMotion()) return;

    const nodes = root.querySelectorAll<HTMLElement>("[data-scramble]");
    const cleanups: Array<() => void> = [];

    nodes.forEach((node) => {
      const original = node.textContent || "";
      const run = () => {
        animate(node, {
          text: scrambleText({
            text: original,
            chars: "uppercase",
          }),
          duration: 700,
          ease: "linear",
        });
      };
      node.addEventListener("pointerenter", run);
      cleanups.push(() => node.removeEventListener("pointerenter", run));
    });

    return () => cleanups.forEach((fn) => fn());
  }, []);

  return ref;
}

/** Hero entrance: brand chars, scramble, copy, CTAs, player, bars + optional drag. */
export function useHeroEntrance(ready = true) {
  const rootRef = useRef<HTMLElement | null>(null);

  useEffect(() => {
    if (!ready) return;
    const root = rootRef.current;
    if (!root) return;

    if (prefersReducedMotion()) return;

    const brand = root.querySelector<HTMLElement>("[data-hero-brand]");
    const lines = root.querySelectorAll<HTMLElement>("[data-hero-line]");
    const ctas = root.querySelectorAll<HTMLElement>("[data-hero-cta]");
    const player = root.querySelector<HTMLElement>("[data-hero-player]");
    const bars = root.querySelectorAll<HTMLElement>("[data-hero-bar]");

    let split: ReturnType<typeof splitText> | null = null;
    let timeline: Timeline | null = null;
    let barLoop: JSAnimation | null = null;
    let drag: ReturnType<typeof createDraggable> | null = null;
    const scope = createScope({ root });

    scope.add(() => {
      if (brand) {
        split = splitText(brand, {
          chars: { class: "hero-char" },
          accessible: true,
        });
      }

      const chars = root.querySelectorAll(".hero-char");
      timeline = createTimeline({ defaults: { ease: EASE_OUT } });

      if (chars.length) {
        chars.forEach((c) => {
          const node = c as HTMLElement;
          node.style.color = "#ffffff";
          node.style.opacity = "0";
        });
        timeline.add(chars, {
          y: [36, 0],
          opacity: [0, 1],
          duration: 720,
          delay: stagger(32),
          ease: createSpring({ stiffness: 140, damping: 16 }),
        });
      } else if (brand) {
        timeline.add(brand, {
          opacity: [0, 1],
          y: [24, 0],
          duration: 700,
        });
      }

      if (lines.length) {
        timeline.add(
          lines,
          {
            opacity: [0, 1],
            y: [28, 0],
            filter: ["blur(10px)", "blur(0px)"],
            duration: 780,
            delay: stagger(100),
          },
          "-=280"
        );
      }

      if (ctas.length) {
        timeline.add(
          ctas,
          {
            opacity: [0, 1],
            y: [18, 0],
            scale: [0.94, 1],
            duration: 620,
            delay: stagger(80),
            ease: createSpring({ stiffness: 160, damping: 14 }),
          },
          "-=420"
        );
      }

      if (player) {
        timeline.add(
          player,
          {
            opacity: [0, 1],
            y: [48, 0],
            rotateX: [8, 0],
            scale: [0.96, 1],
            duration: 980,
          },
          "-=300"
        );

        // Desktop: spring-draggable player card
        if (window.matchMedia("(pointer: fine)").matches) {
          drag = createDraggable(player, {
            x: true,
            y: false,
            containerPadding: 24,
            releaseEase: createSpring({ stiffness: 140, damping: 12 }),
          });
        }
      }

      if (bars.length) {
        barLoop = animate(bars, {
          scaleY: stagger([0.3, 1.12], { from: "center" }),
          opacity: stagger([0.28, 1], { from: "center" }),
          duration: 1500,
          ease: "inOutSine",
          loop: true,
          alternate: true,
          delay: stagger(24, { from: "center" }),
        });
      }
    });

    return () => {
      timeline?.pause();
      barLoop?.pause();
      drag?.revert?.();
      split?.revert?.();
      scope.revert?.();
    };
  }, [ready]);

  return rootRef;
}

/** Soft pulse on interactive controls. */
export function pulseTap(el: HTMLElement | null) {
  if (!el || prefersReducedMotion()) return;
  animate(el, {
    scale: [
      { to: 0.94, duration: 90, ease: "outQuad" },
      { to: 1, duration: 280, ease: createSpring({ stiffness: 280, damping: 14 }) },
    ],
  });
}

/** Spring the floating dock in / out. */
export function useDockMotion(visible: boolean) {
  const ref = useRef<HTMLDivElement | null>(null);
  const primed = useRef(false);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;

    // First paint: stay hidden until the visitor scrolls past the hero.
    if (!primed.current) {
      primed.current = true;
      el.style.opacity = "0";
      el.style.pointerEvents = "none";
      el.style.transform = "translateY(64px)";
      if (!visible) return;
    }

    if (prefersReducedMotion()) {
      el.style.opacity = visible ? "1" : "0";
      el.style.pointerEvents = visible ? "auto" : "none";
      el.style.transform = visible ? "none" : "translateY(64px)";
      return;
    }

    if (visible) {
      el.style.pointerEvents = "auto";
      animate(el, {
        opacity: [0, 1],
        y: [80, 0],
        scale: [0.94, 1],
        duration: 620,
        ease: createSpring({ stiffness: 160, damping: 16 }),
      });
    } else {
      animate(el, {
        opacity: 0,
        y: 64,
        scale: 0.96,
        duration: 320,
        ease: "inQuad",
        onComplete: () => {
          el.style.pointerEvents = "none";
        },
      });
    }
  }, [visible]);

  return ref;
}

/** Navbar mount timeline. */
export function useNavEntrance<T extends HTMLElement = HTMLElement>() {
  const ref = useRef<T | null>(null);

  useEffect(() => {
    const root = ref.current;
    if (!root || prefersReducedMotion()) return;

    const brand = root.querySelector("[data-nav-brand]");
    const links = root.querySelectorAll("[data-nav-link]");
    const actions = root.querySelectorAll("[data-nav-action]");
    const mark = root.querySelector("[data-nav-mark]");

    const tl = createTimeline({ defaults: { ease: EASE_OUT } });

    if (brand) {
      tl.add(brand, { x: [-10, 0], duration: 480 }, 0);
    }
    if (mark) {
      tl.add(mark, { rotate: [-12, 0], scale: [0.86, 1], duration: 560 }, 30);
    }
    if (links.length) {
      tl.add(
        links,
        { y: [-6, 0], delay: stagger(36), duration: 380 },
        90
      );
    }
    if (actions.length) {
      tl.add(
        actions,
        { y: [-6, 0], delay: stagger(36), duration: 380 },
        140
      );
    }

    return () => {
      tl.pause();
      tl.revert?.();
    };
  }, []);

  return ref;
}

/** FAQ accordion open/close with anime height. */
export function animateAccordion(panel: HTMLElement | null, open: boolean) {
  if (!panel) return;
  if (prefersReducedMotion()) {
    panel.style.height = open ? "auto" : "0px";
    panel.style.opacity = open ? "1" : "0";
    return;
  }

  if (open) {
    panel.style.height = "0px";
    panel.style.opacity = "0";
    panel.style.overflow = "hidden";
    const full = panel.scrollHeight;
    animate(panel, {
      height: [`0px`, `${full}px`],
      opacity: [0, 1],
      duration: 380,
      ease: EASE_OUT,
      onComplete: () => {
        panel.style.height = "auto";
      },
    });
  } else {
    const full = panel.scrollHeight;
    panel.style.height = `${full}px`;
    animate(panel, {
      height: [`${full}px`, "0px"],
      opacity: [1, 0],
      duration: 280,
      ease: "inQuad",
    });
  }
}
