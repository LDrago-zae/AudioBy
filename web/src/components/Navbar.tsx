"use client";

import React, { useState } from "react";
import { LogOut, ArrowUpRight, Menu, X, Sun, Moon } from "lucide-react";
import { AudioByMark } from "@/components/AudioByMark";
import { useAuth } from "@/lib/auth-context";
import { useTheme } from "@/lib/theme-context";
import { pulseTap, useNavEntrance, useScrambleHover } from "@/lib/anime-motion";

interface NavbarProps {
  onOpenAuth: () => void;
}

export const Navbar: React.FC<NavbarProps> = ({ onOpenAuth }) => {
  const { user, signOutUser, loading } = useAuth();
  const { toggleTheme, isDark } = useTheme();
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const navRef = useNavEntrance<HTMLElement>();
  const scrambleRef = useScrambleHover<HTMLElement>();

  const navLinks = [
    { label: "Why AudioBy", href: "#problem" },
    { label: "Voice Lab", href: "#lab" },
    { label: "Engine", href: "#engine" },
    { label: "Pricing", href: "#pricing" },
    { label: "FAQ", href: "#faq" },
  ];

  const handleMobileNavClick = (href: string) => {
    setMobileMenuOpen(false);
    document.getElementById(href.replace("#", ""))?.scrollIntoView({ behavior: "smooth" });
  };

  return (
    <header
      ref={(node) => {
        (navRef as React.MutableRefObject<HTMLElement | null>).current = node;
        (scrambleRef as React.MutableRefObject<HTMLElement | null>).current = node;
      }}
      className="sticky top-0 z-50 w-full border-b border-[var(--border-subtle)] bg-[var(--background)]/90 backdrop-blur-md transition-colors duration-200"
    >
      <div className="mx-auto flex h-14 max-w-6xl items-center justify-between px-4 sm:px-6">
        <a href="#" data-nav-brand className="flex items-center gap-2.5 group opacity-0">
          <span
            data-nav-mark
            className="flex h-8 w-8 items-center justify-center rounded-lg bg-emerald text-emerald-ink"
          >
            <AudioByMark className="h-4 w-4" />
          </span>
          <span
            data-scramble
            className="font-display text-base font-bold tracking-tight text-leaf-ink"
          >
            AudioBy
          </span>
        </a>

        <nav className="hidden md:flex items-center gap-6 text-sm font-medium text-leaf-muted">
          {navLinks.map((link) => (
            <a
              key={link.href}
              href={link.href}
              data-nav-link
              className="opacity-0 hover:text-leaf-ink transition-colors"
            >
              {link.label}
            </a>
          ))}
        </nav>

        <div className="flex items-center gap-2">
          <button
            type="button"
            data-nav-action
            onClick={(e) => {
              pulseTap(e.currentTarget);
              toggleTheme();
            }}
            aria-label={isDark ? "Switch to light theme" : "Switch to dark theme"}
            className="opacity-0 flex h-8 w-8 items-center justify-center rounded-lg border border-[var(--border-subtle)] bg-leaf-raised text-leaf-ink hover:border-emerald/40 transition-colors"
          >
            {isDark ? <Sun className="h-3.5 w-3.5 text-amber-300" /> : <Moon className="h-3.5 w-3.5" />}
          </button>

          {!loading && user ? (
            <div className="flex items-center gap-2" data-nav-action>
              <span className="hidden sm:inline-flex items-center gap-1.5 rounded-lg border border-[var(--border-subtle)] bg-leaf-raised px-2.5 py-1 text-xs text-leaf-ink max-w-[140px] truncate">
                <span className="h-1.5 w-1.5 rounded-full bg-emerald shrink-0" />
                {user.displayName || user.email}
              </span>
              <button
                type="button"
                onClick={() => signOutUser()}
                title="Sign out"
                className="flex items-center gap-1 rounded-lg border border-[var(--border-subtle)] px-2 py-1 text-xs text-leaf-muted hover:text-leaf-ink transition-colors"
              >
                <LogOut className="h-3.5 w-3.5" />
                <span className="hidden sm:inline">Sign Out</span>
              </button>
            </div>
          ) : (
            <div className="flex items-center gap-2">
              <button
                type="button"
                data-nav-action
                onClick={onOpenAuth}
                className="opacity-0 rounded-lg border border-[var(--border-subtle)] bg-leaf-raised px-3 py-1.5 text-xs font-semibold text-leaf-ink hover:border-emerald/40 transition-colors"
              >
                Sign In
              </button>
              <a
                href="#pricing"
                data-nav-action
                className="opacity-0 inline-flex items-center gap-1 rounded-lg bg-emerald px-3 py-1.5 text-xs font-bold text-emerald-ink hover:bg-emerald-dark dark:hover:bg-emerald-light transition-colors"
              >
                <span>Plans</span>
                <ArrowUpRight className="h-3 w-3" />
              </a>
            </div>
          )}

          <button
            type="button"
            onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            aria-label="Toggle navigation menu"
            className="flex md:hidden h-8 w-8 items-center justify-center rounded-lg border border-[var(--border-subtle)] text-leaf-ink"
          >
            {mobileMenuOpen ? <X className="h-4 w-4" /> : <Menu className="h-4 w-4" />}
          </button>
        </div>
      </div>

      {mobileMenuOpen && (
        <div className="md:hidden border-t border-[var(--border-subtle)] bg-leaf-surface px-4 py-4">
          <div className="flex flex-col gap-1">
            {navLinks.map((link) => (
              <button
                key={link.href}
                type="button"
                onClick={() => handleMobileNavClick(link.href)}
                className="rounded-lg px-3 py-2.5 text-left text-sm font-medium text-leaf-ink hover:bg-leaf-raised hover:text-emerald-dark dark:hover:text-emerald transition-colors"
              >
                {link.label}
              </button>
            ))}
            <a
              href="https://apps.apple.com/app/audioby/id6807599877"
              target="_blank"
              rel="noreferrer"
              className="mt-2 inline-flex items-center gap-1.5 px-3 py-2 text-sm font-semibold text-emerald-dark dark:text-emerald"
            >
              iOS App
              <ArrowUpRight className="h-3.5 w-3.5" />
            </a>
          </div>
        </div>
      )}
    </header>
  );
};
