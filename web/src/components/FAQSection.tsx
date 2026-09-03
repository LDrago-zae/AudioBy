"use client";

import React, { useState } from "react";
import { motion, AnimatePresence } from "motion/react";
import { ChevronDown } from "lucide-react";

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
    a: "On-device voices run locally on your phone’s neural engine with zero latency and zero data usage—ideal for high-speed skimming. ElevenLabs Studio voices (Premium) use deep acoustic modeling with natural breathing, expressive intonation, and emotional phrasing that sounds indistinguishable from a voice actor in a studio booth.",
  },
  {
    q: "Can I download audiobooks for offline listening?",
    a: "Yes. Plus and Premium members can download entire books and converted documents to their device storage. Everything plays without cellular or Wi-Fi connection.",
  },
  {
    q: "What happens to my data if I cancel?",
    a: "You keep all your bookmarks and history. The 70,000+ public domain catalog remains free forever. Only the premium features (unlimited PDF imports, unlimited downloads, ElevenLabs studio narration) revert to the free starter tier.",
  },
];

export const FAQSection: React.FC = () => {
  const [openIndex, setOpenIndex] = useState<number | null>(0);

  const toggle = (idx: number) => {
    setOpenIndex(openIndex === idx ? null : idx);
  };

  return (
    <section id="faq" className="py-14 sm:py-20 md:py-24 border-t border-black/[0.08] dark:border-white/[0.08] bg-zinc-100/60 dark:bg-[#0B0D11] relative transition-colors duration-200">
      <div className="mx-auto max-w-3xl px-3.5 sm:px-6">
        <div className="text-center mb-8 sm:mb-14">
          <motion.div
            initial={{ opacity: 0, y: -10 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            className="flex items-center justify-center gap-2 mb-3 text-[11px] font-mono tracking-wider uppercase text-zinc-500 dark:text-zinc-400"
          >
            <span className="font-bold text-[#059669] dark:text-[#10B981]">[ 06 ]</span>
            <span className="font-semibold text-zinc-700 dark:text-zinc-300">TECHNICAL SPECIFICATIONS & QUERIES</span>
          </motion.div>

          <motion.h2
            initial={{ opacity: 0, y: 14 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ delay: 0.1 }}
            className="text-2xl sm:text-3xl md:text-4xl font-bold tracking-tight text-zinc-950 dark:text-white"
          >
            Questions, answered plainly.
          </motion.h2>

          <motion.p
            initial={{ opacity: 0, y: 14 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ delay: 0.2 }}
            className="mt-2 text-xs sm:text-base text-zinc-600 dark:text-zinc-400"
          >
            Clear architectural details on local privacy, synchronization, and voice models.
          </motion.p>
        </div>

        <div className="space-y-3">
          {FAQS.map((faq, idx) => {
            const isOpen = openIndex === idx;
            return (
              <motion.div
                key={idx}
                initial={{ opacity: 0, y: 12 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ duration: 0.4, delay: idx * 0.05 }}
                className="rounded-xl border border-black/[0.08] dark:border-white/[0.08] bg-white dark:bg-[#0E1015] overflow-hidden transition-colors shadow-sm"
              >
                <button
                  onClick={() => toggle(idx)}
                  className="flex w-full items-center justify-between p-4 sm:p-5 text-left text-xs sm:text-sm font-bold text-zinc-950 dark:text-white hover:text-[#059669] dark:hover:text-[#10B981] transition-colors gap-3"
                >
                  <span>{faq.q}</span>
                  <motion.div
                    animate={{ rotate: isOpen ? 180 : 0 }}
                    transition={{ duration: 0.25 }}
                    className="shrink-0 text-zinc-400 dark:text-zinc-500"
                  >
                    <ChevronDown className="h-4 w-4" />
                  </motion.div>
                </button>

                <AnimatePresence initial={false}>
                  {isOpen && (
                    <motion.div
                      initial={{ height: 0, opacity: 0 }}
                      animate={{ height: "auto", opacity: 1 }}
                      exit={{ height: 0, opacity: 0 }}
                      transition={{ duration: 0.3, ease: [0.16, 1, 0.3, 1] }}
                      className="overflow-hidden"
                    >
                      <div className="px-4 sm:px-5 pb-4 sm:pb-5 text-xs sm:text-sm text-zinc-600 dark:text-zinc-400 leading-relaxed border-t border-black/[0.04] dark:border-white/[0.04] pt-3 sm:pt-4">
                        {faq.a}
                      </div>
                    </motion.div>
                  )}
                </AnimatePresence>
              </motion.div>
            );
          })}
        </div>
      </div>
    </section>
  );
};
