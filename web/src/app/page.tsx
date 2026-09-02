"use client";

import React, { useState } from "react";
import { Navbar } from "@/components/Navbar";
import { HeroSection } from "@/components/HeroSection";
import { ProofStrip } from "@/components/ProofStrip";
import { ProblemSection } from "@/components/ProblemSection";
import { InteractivePlayer } from "@/components/InteractivePlayer";
import { TimeCalculator } from "@/components/TimeCalculator";
import { FeatureDeepDives } from "@/components/FeatureDeepDives";
import { CraftManifesto } from "@/components/CraftManifesto";
import { PricingSection } from "@/components/PricingSection";
import { FAQSection } from "@/components/FAQSection";
import { Footer } from "@/components/Footer";
import { AuthModal } from "@/components/AuthModal";
import { CheckoutModal } from "@/components/CheckoutModal";
import { FloatingPlayerDock } from "@/components/FloatingPlayerDock";
import { useAuth } from "@/lib/auth-context";

export default function HomePage() {
  const { user } = useAuth();
  const [authOpen, setAuthOpen] = useState(false);
  const [checkoutOpen, setCheckoutOpen] = useState(false);
  const [selectedPlan, setSelectedPlan] = useState<"plus" | "premium" | null>(null);

  const handleSelectPlan = (plan: "plus" | "premium") => {
    setSelectedPlan(plan);
    if (!user) {
      setAuthOpen(true);
    } else {
      setCheckoutOpen(true);
    }
  };

  const handleAuthSuccess = () => {
    if (selectedPlan) {
      setCheckoutOpen(true);
    }
  };

  const scrollToPricing = () => {
    const el = document.getElementById("pricing");
    el?.scrollIntoView({ behavior: "smooth" });
  };

  return (
    <div className="relative min-h-screen bg-[#F9FAF9] dark:bg-[#0C100E] text-[#111813] dark:text-ink-primary font-sans transition-colors duration-200">
      {/* Sticky Header */}
      <Navbar onOpenAuth={() => setAuthOpen(true)} />

      <main>
        {/* Editorial Hero */}
        <HeroSection onExplorePlans={scrollToPricing} />

        {/* Proof / Stat Strip */}
        <ProofStrip />

        {/* The Problem: Why screen reading fails */}
        <ProblemSection />

        {/* Interactive Voice & PDF Lab */}
        <InteractivePlayer />

        {/* Interactive Time / Reading Calculator */}
        <TimeCalculator />

        {/* Numbered Feature Deep-Dives 01-04 */}
        <FeatureDeepDives />

        {/* Indie / Craft Manifesto */}
        <CraftManifesto />

        {/* Pricing & Subscription Switcher */}
        <PricingSection onSelectPlan={handleSelectPlan} />

        {/* FAQ */}
        <FAQSection />
      </main>

      {/* Floating Dynamic Island Audio Player */}
      <FloatingPlayerDock onUpgrade={scrollToPricing} />

      {/* Footer */}
      <Footer />

      {/* Auth Dialog */}
      <AuthModal
        isOpen={authOpen}
        onClose={() => setAuthOpen(false)}
        onSuccess={handleAuthSuccess}
      />

      {/* Cross-Platform Checkout Dialog */}
      <CheckoutModal
        isOpen={checkoutOpen}
        plan={selectedPlan}
        onClose={() => {
          setCheckoutOpen(false);
          setSelectedPlan(null);
        }}
        onRequireAuth={() => {
          setCheckoutOpen(false);
          setAuthOpen(true);
        }}
      />
    </div>
  );
}
