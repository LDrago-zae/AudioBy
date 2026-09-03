"use client";

import React, { useState } from "react";
import { Headphones, LogOut, ArrowUpRight, Menu, X, Sun, Moon } from "lucide-react";
import { motion, AnimatePresence } from "motion/react";
import { useAuth } from "@/lib/auth-context";
import { useTheme } from "@/lib/theme-context";

interface NavbarProps {
  onOpenAuth: () => void;
}

export const Navbar: React.FC<NavbarProps> = ({ onOpenAuth }) => {
  const { user, signOutUser, loading } = useAuth();
  const { theme, toggleTheme, isDark } = useTheme();
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  const navLinks = [
    { label: "Why AudioBy", href: "#problem" },
    { label: "Voice Lab", href: "#lab" },
    { label: "Engine Specs", href: "#engine" },
    { label: "Time Saved", href: "#calculator" },
    { label: "Pricing", href: "#pricing" },
    { label: "FAQ", href: "#faq" },
  ];

  const handleMobileNavClick = (href: string) => {
    setMobileMenuOpen(false);
    const id = href.replace("#", "");
    const el = document.getElementById(id);
    if (el) {
      el.scrollIntoView({ behavior: "smooth" });
    }
  };

  return (
    <header className="sticky top-0 z-50 w-full border-b border-black/[0.08] dark:border-white/[0.08] bg-[#F8FAF8]/95 dark:bg-[#08090B]/95 backdrop-blur-md transition-colors duration-200">
      <div className="mx-auto flex h-14 max-w-6xl items-center justify-between px-3.5 sm:px-6">
        {/* Brand */}
        <div className="flex items-center gap-2 sm:gap-3">
          <a href="#" className="flex items-center gap-2 sm:gap-2.5 group">
            <div className="flex h-7 w-7 items-center justify-center rounded-lg bg-black/[0.04] dark:bg-[#12151B] border border-black/[0.08] dark:border-white/[0.1] text-[#059669] dark:text-[#10B981]">
              <Headphones className="h-3.5 w-3.5" />
            </div>
            <span className="text-sm font-semibold tracking-tight text-zinc-950 dark:text-white">AudioBy</span>
          </a>
          <span className="hidden sm:inline-block rounded-md border border-black/[0.08] dark:border-white/[0.1] bg-black/[0.03] dark:bg-[#12151B] px-2 py-0.5 text-[10px] font-mono uppercase tracking-wider text-zinc-600 dark:text-zinc-400">
            v1.2 · iOS & Web
          </span>
        </div>

        {/* Desktop Navigation */}
        <nav className="hidden md:flex items-center gap-6 lg:gap-7 text-xs font-medium text-zinc-600 dark:text-zinc-400">
          {navLinks.map((link) => (
            <a
              key={link.href}
              href={link.href}
              className="hover:text-zinc-950 dark:hover:text-white transition-colors"
            >
              {link.label}
            </a>
          ))}
        </nav>

        {/* Right CTA / Theme Toggle / Mobile toggle */}
        <div className="flex items-center gap-2">
          {/* Theme Toggle Button */}
          <motion.button
            whileTap={{ scale: 0.92 }}
            onClick={toggleTheme}
            aria-label={isDark ? "Switch to light theme" : "Switch to dark theme"}
            title={isDark ? "Light mode" : "Dark mode"}
            className="flex h-8 w-8 items-center justify-center rounded-lg border border-black/[0.08] dark:border-white/[0.1] bg-black/[0.03] dark:bg-[#12151B] text-zinc-700 dark:text-zinc-300 hover:text-zinc-950 dark:hover:text-white hover:border-black/20 dark:hover:border-white/20 transition-colors cursor-pointer"
          >
            {isDark ? (
              <Sun className="h-3.5 w-3.5 text-amber-400" />
            ) : (
              <Moon className="h-3.5 w-3.5 text-zinc-700" />
            )}
          </motion.button>

          {!loading && user ? (
            <div className="flex items-center gap-1.5 sm:gap-2">
              <span className="hidden sm:inline-flex items-center gap-1.5 rounded-md border border-black/[0.08] dark:border-white/[0.1] bg-black/[0.03] dark:bg-[#12151B] px-2.5 py-1 text-xs text-zinc-800 dark:text-zinc-200 font-mono">
                <span className="h-1.5 w-1.5 rounded-full bg-[#10B981]" />
                <span className="max-w-[120px] truncate">{user.displayName || user.email}</span>
              </span>
              <button
                onClick={() => signOutUser()}
                title="Sign out"
                className="flex items-center gap-1 rounded-md border border-black/[0.08] dark:border-white/[0.1] bg-black/[0.03] dark:bg-[#12151B] px-2 sm:px-2.5 py-1 text-xs text-zinc-600 dark:text-zinc-400 hover:text-zinc-950 dark:hover:text-white hover:border-black/20 dark:hover:border-white/20 transition-colors"
              >
                <LogOut className="h-3.5 w-3.5" />
                <span className="hidden sm:inline">Sign Out</span>
              </button>
            </div>
          ) : (
            <div className="flex items-center gap-1.5 sm:gap-2">
              <button
                onClick={onOpenAuth}
                className="rounded-lg border border-black/[0.08] dark:border-white/[0.1] bg-black/[0.03] dark:bg-[#12151B] px-2.5 sm:px-3 py-1.5 text-xs font-medium text-zinc-800 dark:text-zinc-200 hover:bg-black/[0.06] dark:hover:bg-[#1A1E26] hover:border-black/20 dark:hover:border-white/20 transition-colors"
              >
                Sign In
              </button>
              <a
                href="#pricing"
                className="inline-flex items-center gap-1 rounded-lg bg-[#10B981] hover:bg-[#059669] dark:hover:bg-[#34D399] px-2.5 sm:px-3 py-1.5 text-xs font-semibold text-black transition-colors"
              >
                <span>Plans</span>
                <ArrowUpRight className="h-3 w-3" />
              </a>
            </div>
          )}

          {/* Mobile Menu Toggle Button */}
          <button
            onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            aria-label="Toggle navigation menu"
            className="flex md:hidden h-8 w-8 items-center justify-center rounded-lg border border-black/[0.08] dark:border-white/[0.1] bg-black/[0.03] dark:bg-[#12151B] text-zinc-700 dark:text-zinc-300 hover:text-zinc-950 dark:hover:text-white transition-colors"
          >
            {mobileMenuOpen ? <X className="h-4 w-4" /> : <Menu className="h-4 w-4" />}
          </button>
        </div>
      </div>

      {/* Mobile Animated Dropdown Drawer */}
      <AnimatePresence>
        {mobileMenuOpen && (
          <motion.div
            initial={{ height: 0, opacity: 0 }}
            animate={{ height: "auto", opacity: 1 }}
            exit={{ height: 0, opacity: 0 }}
            transition={{ duration: 0.22, ease: "easeInOut" }}
            className="md:hidden border-t border-black/[0.08] dark:border-white/[0.08] bg-zinc-100 dark:bg-[#0B0D11] px-4 py-4 overflow-hidden"
          >
            <div className="flex flex-col space-y-1">
              {navLinks.map((link) => (
                <button
                  key={link.href}
                  onClick={() => handleMobileNavClick(link.href)}
                  className="flex items-center justify-between rounded-lg px-3 py-2.5 text-left text-xs font-medium text-zinc-800 dark:text-zinc-200 hover:bg-white dark:hover:bg-[#14171E] hover:text-[#059669] dark:hover:text-[#10B981] transition-colors"
                >
                  <span>{link.label}</span>
                  <span className="text-[10px] font-mono text-zinc-400 dark:text-zinc-500">→</span>
                </button>
              ))}

              <div className="pt-3 mt-2 border-t border-black/[0.06] dark:border-white/[0.06] flex items-center justify-between">
                <button
                  onClick={toggleTheme}
                  className="flex items-center gap-2 text-xs font-mono font-medium text-zinc-700 dark:text-zinc-300 hover:text-zinc-950 dark:hover:text-white transition-colors"
                >
                  {isDark ? (
                    <>
                      <Sun className="h-3.5 w-3.5 text-amber-400" />
                      <span>Switch to Light Theme</span>
                    </>
                  ) : (
                    <>
                      <Moon className="h-3.5 w-3.5 text-zinc-700" />
                      <span>Switch to Dark Theme</span>
                    </>
                  )}
                </button>

                <a
                  href="https://apps.apple.com/app/audioby/id6807599877"
                  target="_blank"
                  rel="noreferrer"
                  className="flex items-center gap-1.5 text-xs font-mono text-[#059669] dark:text-[#10B981] hover:underline"
                >
                  <span>iOS App</span>
                  <ArrowUpRight className="h-3.5 w-3.5" />
                </a>
              </div>

              {user && (
                <div className="pt-2 text-right">
                  <button
                    onClick={() => {
                      setMobileMenuOpen(false);
                      signOutUser();
                    }}
                    className="text-xs text-rose-500 hover:underline font-mono"
                  >
                    Log Out
                  </button>
                </div>
              )}
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </header>
  );
};
