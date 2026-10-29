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
    document.getElementById("pricing")?.scrollIntoView({ behavior: "smooth" });
  };

  return (
    <div className="relative min-h-screen bg-[var(--background)] text-leaf-ink font-body">
      <Navbar onOpenAuth={() => setAuthOpen(true)} />

      <main>
        <HeroSection onExplorePlans={scrollToPricing} />
        <ProofStrip />
        <ProblemSection />
        <InteractivePlayer />
        <TimeCalculator />
        <FeatureDeepDives />
        <CraftManifesto />
        <PricingSection onSelectPlan={handleSelectPlan} />
        <FAQSection />
      </main>

      <FloatingPlayerDock onUpgrade={scrollToPricing} />
      <Footer />

      <AuthModal
        isOpen={authOpen}
        onClose={() => setAuthOpen(false)}
        onSuccess={handleAuthSuccess}
      />

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
