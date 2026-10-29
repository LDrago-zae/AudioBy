"use client";

import React, { useEffect, useRef, useState } from "react";
import { ChevronDown } from "lucide-react";
import { animateAccordion, useScrollReveal, useSplitHeading } from "@/lib/anime-motion";

interface FAQItem {
  q: string;
  a: string;
}

const FAQS: FAQItem[] = [
  {
    q: "How does web subscription syncing work with the iOS app?",
    a: "When you subscribe to Plus or Premium on our website, your active entitlement is bound to your Firebase account in RevenueCat. When you open the AudioBy iOS app and sign in with that same email, your features unlock automatically—no duplicate App Store purchase needed.",
  },
  {
    q: "Do my uploaded PDFs get sent to an AI training pool?",
    a: "Never. Your documents are parsed exclusively for text extraction and speech synthesis on your device. We do not sell your documents, train language models on your files, or retain them on public servers.",
  },
  {
    q: "What is the difference between on-device voices and ElevenLabs Studio voices?",
    a: "On-device voices run locally on your phone’s neural engine with zero latency and zero data usage—ideal for high-speed skimming. ElevenLabs Studio voices (Premium) use deep acoustic modeling with natural breathing, expressive intonation, and emotional phrasing that sounds indistinguishable from a studio voice actor.",
  },
  {
    q: "Can I download audiobooks for offline listening?",
    a: "Yes. Plus and Premium members can download entire books and converted documents to their device storage. Everything plays without cellular or Wi-Fi.",
  },
  {
    q: "What happens to my data if I cancel?",
    a: "You keep all your bookmarks and history. The 70,000+ public domain catalog remains free forever. Only premium features (unlimited PDF imports, unlimited downloads, ElevenLabs studio narration) revert to the free starter tier.",
  },
];

export const FAQSection: React.FC = () => {
  const [openIndex, setOpenIndex] = useState<number | null>(0);
  const revealRef = useScrollReveal<HTMLElement>();
  const splitRef = useSplitHeading<HTMLElement>();
  const panelsRef = useRef<Array<HTMLDivElement | null>>([]);

  useEffect(() => {
    panelsRef.current.forEach((panel, idx) => {
      if (!panel) return;
      const shouldOpen = openIndex === idx;
      if (idx === 0 && openIndex === 0 && panel.dataset.primed !== "1") {
        panel.style.height = "auto";
        panel.style.opacity = "1";
        panel.dataset.primed = "1";
        return;
      }
      animateAccordion(panel, shouldOpen);
      panel.dataset.primed = "1";
    });
  }, [openIndex]);

  return (
    <section
      id="faq"
      ref={(node) => {
        (revealRef as React.MutableRefObject<HTMLElement | null>).current = node;
        (splitRef as React.MutableRefObject<HTMLElement | null>).current = node;
      }}
      className="py-20 sm:py-28 border-t border-[var(--border-subtle)] bg-leaf-surface"
    >
      <div className="mx-auto max-w-3xl px-4 sm:px-6">
        <h2
          data-split
          className="font-display text-3xl sm:text-4xl font-bold tracking-tight text-leaf-ink mb-12 sm:mb-16 leading-[1.1]"
        >
          Questions, answered plainly.
        </h2>

        <div className="divide-y divide-[var(--border-subtle)] border-y border-[var(--border-subtle)]">
          {FAQS.map((item, idx) => {
            const open = openIndex === idx;
            return (
              <div
                key={item.q}
                data-reveal
                className="overflow-hidden"
              >
                <button
                  type="button"
                  onClick={() => setOpenIndex(open ? null : idx)}
                  className="w-full flex items-center justify-between gap-4 py-5 text-left hover:text-emerald-dark dark:hover:text-emerald transition-colors"
                  aria-expanded={open}
                >
                  <span className="font-display text-sm sm:text-base font-bold text-leaf-ink pr-2">
                    {item.q}
                  </span>
                  <ChevronDown
                    className={`h-4 w-4 shrink-0 text-leaf-muted transition-transform duration-300 ${open ? "rotate-180" : ""}`}
                  />
                </button>
                <div
                  ref={(el) => {
                    panelsRef.current[idx] = el;
                  }}
                  className="overflow-hidden"
                  style={{
                    height: idx === 0 ? "auto" : "0px",
                    opacity: idx === 0 ? 1 : 0,
                  }}
                >
                  <div className="pb-5 text-sm text-leaf-muted leading-relaxed max-w-measure">
                    {item.a}
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </section>
  );
};
