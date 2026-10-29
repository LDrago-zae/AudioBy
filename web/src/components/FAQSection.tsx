"use client";

import React, { useState } from "react";
import { ChevronDown } from "lucide-react";
import { useScrollReveal } from "@/lib/anime-motion";

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
  const ref = useScrollReveal<HTMLElement>();

  return (
    <section
      id="faq"
      ref={ref}
      className="py-16 sm:py-24 border-t border-[var(--border-subtle)] bg-leaf-surface"
    >
      <div className="mx-auto max-w-3xl px-4 sm:px-6">
        <h2
          data-reveal
          className="font-display text-3xl sm:text-4xl font-bold tracking-tight text-leaf-ink text-center mb-10 sm:mb-14"
        >
          Questions, answered plainly.
        </h2>

        <div className="space-y-2">
          {FAQS.map((item, idx) => {
            const open = openIndex === idx;
            return (
              <div
                key={item.q}
                data-reveal
                className="rounded-xl border border-[var(--border-subtle)] bg-leaf-raised overflow-hidden"
              >
                <button
                  type="button"
                  onClick={() => setOpenIndex(open ? null : idx)}
                  className="w-full flex items-center justify-between gap-4 px-4 sm:px-5 py-4 text-left"
                  aria-expanded={open}
                >
                  <span className="font-display text-sm sm:text-base font-bold text-leaf-ink pr-2">
                    {item.q}
                  </span>
                  <ChevronDown
                    className={`h-4 w-4 shrink-0 text-leaf-muted transition-transform ${open ? "rotate-180" : ""}`}
                  />
                </button>
                {open && (
                  <div className="px-4 sm:px-5 pb-4 text-sm text-leaf-muted leading-relaxed border-t border-[var(--border-subtle)] pt-3">
                    {item.a}
                  </div>
                )}
              </div>
            );
          })}
        </div>
      </div>
    </section>
  );
};
