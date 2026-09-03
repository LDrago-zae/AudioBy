"use client";

import React, { useState } from "react";
import { motion, AnimatePresence } from "motion/react";
import { X, Mail, Lock, User, ArrowRight, Loader2 } from "lucide-react";
import { useAuth } from "@/lib/auth-context";

interface AuthModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSuccess?: () => void;
}

export const AuthModal: React.FC<AuthModalProps> = ({ isOpen, onClose, onSuccess }) => {
  const { signInWithGoogle, signInWithEmail, signUpWithEmail, error, clearError } = useAuth();
  const [mode, setMode] = useState<"signin" | "signup">("signin");
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [localError, setLocalError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLocalError(null);
    clearError();
    setIsSubmitting(true);

    try {
      if (mode === "signup") {
        await signUpWithEmail(name, email, password);
      } else {
        await signInWithEmail(email, password);
      }
      onSuccess?.();
      onClose();
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : "Authentication failed";
      setLocalError(message);
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleGoogle = async () => {
    setLocalError(null);
    clearError();
    setIsSubmitting(true);
    try {
      await signInWithGoogle();
      onSuccess?.();
      onClose();
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : "Google sign in failed";
      setLocalError(message);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <AnimatePresence>
      {isOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          {/* Backdrop */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={onClose}
            className="fixed inset-0 bg-black/60 dark:bg-black/80 backdrop-blur-md"
          />

          {/* Modal Container */}
          <motion.div
            initial={{ scale: 0.94, opacity: 0, y: 16 }}
            animate={{ scale: 1, opacity: 1, y: 0 }}
            exit={{ scale: 0.94, opacity: 0, y: 16 }}
            transition={{ type: "spring", stiffness: 350, damping: 25 }}
            className="relative w-full max-w-sm rounded-2xl border border-black/10 dark:border-white/[0.1] bg-white dark:bg-[#0E1015] p-5 sm:p-6 shadow-2xl z-10 max-h-[92vh] overflow-y-auto transition-colors"
          >
            {/* Close Button */}
            <button
              onClick={onClose}
              className="absolute right-4 top-4 rounded-lg p-1 text-zinc-400 hover:bg-black/[0.04] dark:hover:bg-[#161922] hover:text-zinc-800 dark:hover:text-white transition-colors"
            >
              <X className="h-4 w-4" />
            </button>

            {/* Title */}
            <div className="text-left mb-6">
              <h3 className="text-xl font-bold text-zinc-950 dark:text-white">
                {mode === "signin" ? "Sign In to AudioBy" : "Create Account"}
              </h3>
              <p className="mt-1 text-xs text-zinc-500 dark:text-zinc-400">
                {mode === "signin"
                  ? "Access your library and synchronized subscription."
                  : "Set up your account for cross-device listening."}
              </p>
            </div>

            {/* Tab switch */}
            <div className="flex rounded-xl bg-black/[0.04] dark:bg-[#07080A] p-1 border border-black/[0.06] dark:border-white/[0.06] mb-5">
              <button
                onClick={() => {
                  setMode("signin");
                  setLocalError(null);
                }}
                className={`flex-1 rounded-lg py-1.5 text-xs font-semibold transition-colors ${
                  mode === "signin"
                    ? "bg-white dark:bg-[#161922] text-zinc-950 dark:text-white border border-black/10 dark:border-white/10 shadow-sm"
                    : "text-zinc-500 dark:text-zinc-400 hover:text-zinc-950 dark:hover:text-white"
                }`}
              >
                Sign In
              </button>
              <button
                onClick={() => {
                  setMode("signup");
                  setLocalError(null);
                }}
                className={`flex-1 rounded-lg py-1.5 text-xs font-semibold transition-colors ${
                  mode === "signup"
                    ? "bg-white dark:bg-[#161922] text-zinc-950 dark:text-white border border-black/10 dark:border-white/10 shadow-sm"
                    : "text-zinc-500 dark:text-zinc-400 hover:text-zinc-950 dark:hover:text-white"
                }`}
              >
                Sign Up
              </button>
            </div>

            {/* Google Sign In */}
            <button
              onClick={handleGoogle}
              disabled={isSubmitting}
              className="flex w-full items-center justify-center gap-2 rounded-xl border border-black/[0.08] dark:border-white/[0.1] bg-black/[0.02] dark:bg-[#12151B] py-2.5 text-xs font-medium text-zinc-800 dark:text-zinc-200 hover:bg-black/[0.05] dark:hover:bg-[#181D26] hover:border-black/20 dark:hover:border-white/20 transition-colors disabled:opacity-50"
            >
              <svg className="h-4 w-4" viewBox="0 0 24 24">
                <path
                  fill="#4285F4"
                  d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
                />
                <path
                  fill="#34A853"
                  d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
                />
                <path
                  fill="#FBBC05"
                  d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.06H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.94l2.85-2.22.81-.63z"
                />
                <path
                  fill="#EA4335"
                  d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.06l3.66 2.84c.87-2.6 3.3-4.52 6.16-4.52z"
                />
              </svg>
              <span>Continue with Google</span>
            </button>

            {/* Divider */}
            <div className="relative my-4 flex items-center justify-center">
              <div className="w-full border-t border-black/[0.08] dark:border-white/[0.08]" />
              <span className="absolute bg-white dark:bg-[#0E1015] px-2 text-[10px] font-mono uppercase text-zinc-400 dark:text-zinc-500">
                Or email
              </span>
            </div>

            {/* Error banner */}
            {(localError || error) && (
              <div className="mb-4 rounded-lg bg-rose-500/10 border border-rose-500/20 p-2.5 text-xs text-rose-500 dark:text-rose-400">
                {localError || error}
              </div>
            )}

            {/* Form */}
            <form onSubmit={handleSubmit} className="space-y-3">
              {mode === "signup" && (
                <div className="relative">
                  <User className="absolute left-3 top-3 h-4 w-4 text-zinc-400" />
                  <input
                    type="text"
                    required
                    placeholder="Full name"
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    className="w-full rounded-xl border border-black/[0.08] dark:border-white/[0.08] bg-zinc-50 dark:bg-[#07080A] py-2.5 pl-9 pr-3 text-xs text-zinc-900 dark:text-white placeholder-zinc-400 focus:border-[#10B981] focus:outline-none transition-colors"
                  />
                </div>
              )}

              <div className="relative">
                <Mail className="absolute left-3 top-3 h-4 w-4 text-zinc-400" />
                <input
                  type="email"
                  required
                  placeholder="Email address"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  className="w-full rounded-xl border border-black/[0.08] dark:border-white/[0.08] bg-zinc-50 dark:bg-[#07080A] py-2.5 pl-9 pr-3 text-xs text-zinc-900 dark:text-white placeholder-zinc-400 focus:border-[#10B981] focus:outline-none transition-colors"
                />
              </div>

              <div className="relative">
                <Lock className="absolute left-3 top-3 h-4 w-4 text-zinc-400" />
                <input
                  type="password"
                  required
                  placeholder="Password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="w-full rounded-xl border border-black/[0.08] dark:border-white/[0.08] bg-zinc-50 dark:bg-[#07080A] py-2.5 pl-9 pr-3 text-xs text-zinc-900 dark:text-white placeholder-zinc-400 focus:border-[#10B981] focus:outline-none transition-colors"
                />
              </div>

              <button
                type="submit"
                disabled={isSubmitting}
                className="mt-2 flex w-full items-center justify-center gap-1.5 rounded-xl bg-[#10B981] hover:bg-[#059669] dark:hover:bg-[#34D399] py-2.5 text-xs font-semibold text-black transition-colors disabled:opacity-50"
              >
                {isSubmitting ? (
                  <Loader2 className="h-4 w-4 animate-spin" />
                ) : (
                  <>
                    <span>{mode === "signin" ? "Sign In" : "Create Account"}</span>
                    <ArrowRight className="h-3.5 w-3.5" />
                  </>
                )}
              </button>
            </form>
          </motion.div>
        </div>
      )}
    </AnimatePresence>
  );
};
