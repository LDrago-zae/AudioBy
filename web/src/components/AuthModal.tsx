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
            className="relative w-full max-w-sm rounded-2xl border border-black/10 dark:border-white/10 bg-white dark:bg-[#161D17] p-5 sm:p-6 shadow-2xl z-10 max-h-[92vh] overflow-y-auto transition-colors"
          >
            {/* Close Button */}
            <button
              onClick={onClose}
              className="absolute right-4 top-4 rounded-lg p-1 text-zinc-400 hover:bg-black/[0.04] dark:hover:bg-[#1A211B] hover:text-zinc-800 dark:hover:text-white transition-colors"
            >
              <X className="h-4 w-4" />
            </button>

            {/* Title */}
            <div className="text-left mb-6">
              <h3 className="text-xl font-bold text-zinc-900 dark:text-white">
                {mode === "signin" ? "Sign In to AudioBy" : "Create Account"}
              </h3>
              <p className="mt-1 text-xs text-zinc-500 dark:text-slate-400">
                {mode === "signin"
                  ? "Access your library and synchronized subscription."
                  : "Set up your account for cross-device listening."}
              </p>
            </div>

            {/* Tab switch */}
            <div className="flex rounded-xl bg-black/[0.04] dark:bg-[#0D150F] p-1 border border-black/[0.06] dark:border-white/5 mb-5">
              <button
                onClick={() => {
                  setMode("signin");
                  setLocalError(null);
                }}
                className={`flex-1 rounded-lg py-1.5 text-xs font-semibold transition-colors ${
                  mode === "signin"
                    ? "bg-white dark:bg-[#1A211B] text-zinc-900 dark:text-white border border-black/10 dark:border-white/10 shadow-sm"
                    : "text-zinc-500 dark:text-slate-400 hover:text-zinc-900 dark:hover:text-white"
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
                    ? "bg-white dark:bg-[#1A211B] text-zinc-900 dark:text-white border border-black/10 dark:border-white/10 shadow-sm"
                    : "text-zinc-500 dark:text-slate-400 hover:text-zinc-900 dark:hover:text-white"
                }`}
              >
                Create Account
              </button>
            </div>

            {/* Google Sign In */}
            <motion.button
              whileTap={{ scale: 0.98 }}
              type="button"
              onClick={handleGoogle}
              disabled={isSubmitting}
              className="flex w-full items-center justify-center gap-2.5 rounded-xl border border-black/10 dark:border-white/10 bg-black/[0.03] dark:bg-[#1A211B] px-4 py-2.5 text-xs font-semibold text-zinc-800 dark:text-white hover:bg-black/[0.06] dark:hover:bg-[#222C24] transition-colors disabled:opacity-50"
            >
              <svg className="h-4 w-4" viewBox="0 0 24 24">
                <path
                  fill="#4285F4"
                  d="M23.745 12.27c0-.7-.06-1.4-.19-2.07H12v4.51h6.6c-.29 1.52-1.14 2.8-2.4 3.68v3.05h3.88c2.27-2.09 3.665-5.17 3.665-9.17z"
                />
                <path
                  fill="#34A853"
                  d="M12 24c3.24 0 5.95-1.08 7.93-2.91l-3.88-3.05c-1.08.72-2.45 1.16-4.05 1.16-3.12 0-5.77-2.1-6.72-4.93H1.25v3.15C3.26 21.36 7.33 24 12 24z"
                />
                <path
                  fill="#FBBC05"
                  d="M5.28 14.27c-.25-.72-.38-1.49-.38-2.27s.13-1.55.38-2.27V6.58H1.25C.45 8.18 0 9.99 0 12s.45 3.82 1.25 5.42l4.03-3.15z"
                />
                <path
                  fill="#EA4335"
                  d="M12 4.75c1.77 0 3.35.61 4.6 1.8l3.42-3.42C17.95 1.19 15.24 0 12 0 7.33 0 3.26 2.64 1.25 6.58l4.03 3.15c.95-2.83 3.6-4.98 6.72-4.98z"
                />
              </svg>
              <span>Continue with Google</span>
            </motion.button>

            <div className="relative my-4 text-center">
              <div className="absolute inset-0 flex items-center">
                <div className="w-full border-t border-black/[0.08] dark:border-white/5" />
              </div>
              <span className="relative bg-white dark:bg-[#161D17] px-2 text-[10px] uppercase font-mono tracking-wider text-zinc-400 dark:text-slate-500">
                or with email
              </span>
            </div>

            {/* Form */}
            <form onSubmit={handleSubmit} className="space-y-3.5">
              {mode === "signup" && (
                <div>
                  <label className="block text-[11px] font-medium text-zinc-700 dark:text-slate-400 mb-1">Name</label>
                  <div className="relative">
                    <User className="absolute left-3 top-2.5 h-4 w-4 text-zinc-400 dark:text-slate-500" />
                    <input
                      type="text"
                      required
                      value={name}
                      onChange={(e) => setName(e.target.value)}
                      placeholder="Your Name"
                      className="w-full rounded-xl border border-black/15 dark:border-white/10 bg-[#F5F8F5] dark:bg-[#0D150F] py-2 pl-9 pr-3 text-xs text-zinc-900 dark:text-white placeholder-zinc-400 dark:placeholder-slate-600 focus:border-[#0F9B51] dark:focus:border-emerald focus:outline-none"
                    />
                  </div>
                </div>
              )}

              <div>
                <label className="block text-[11px] font-medium text-zinc-700 dark:text-slate-400 mb-1">Email</label>
                <div className="relative">
                  <Mail className="absolute left-3 top-2.5 h-4 w-4 text-zinc-400 dark:text-slate-500" />
                  <input
                    type="email"
                    required
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    placeholder="name@example.com"
                    className="w-full rounded-xl border border-black/15 dark:border-white/10 bg-[#F5F8F5] dark:bg-[#0D150F] py-2 pl-9 pr-3 text-xs text-zinc-900 dark:text-white placeholder-zinc-400 dark:placeholder-slate-600 focus:border-[#0F9B51] dark:focus:border-emerald focus:outline-none"
                  />
                </div>
              </div>

              <div>
                <label className="block text-[11px] font-medium text-zinc-700 dark:text-slate-400 mb-1">Password</label>
                <div className="relative">
                  <Lock className="absolute left-3 top-2.5 h-4 w-4 text-zinc-400 dark:text-slate-500" />
                  <input
                    type="password"
                    required
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    placeholder="••••••••"
                    minLength={6}
                    className="w-full rounded-xl border border-black/15 dark:border-white/10 bg-[#F5F8F5] dark:bg-[#0D150F] py-2 pl-9 pr-3 text-xs text-zinc-900 dark:text-white placeholder-zinc-400 dark:placeholder-slate-600 focus:border-[#0F9B51] dark:focus:border-emerald focus:outline-none"
                  />
                </div>
              </div>

              {(localError || error) && (
                <div className="rounded-xl border border-rose-500/20 bg-rose-500/10 p-2.5 text-xs text-rose-500 dark:text-rose-300">
                  {localError || error}
                </div>
              )}

              <motion.button
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
                type="submit"
                disabled={isSubmitting}
                className="flex w-full items-center justify-center gap-1.5 rounded-xl bg-emerald py-2.5 text-xs font-bold text-black hover:bg-emerald-light transition-colors disabled:opacity-50 mt-4 shadow-md"
              >
                {isSubmitting ? (
                  <Loader2 className="h-4 w-4 animate-spin text-black" />
                ) : (
                  <>
                    <span>{mode === "signin" ? "Sign In" : "Create Account"}</span>
                    <ArrowRight className="h-3.5 w-3.5" />
                  </>
                )}
              </motion.button>
            </form>
          </motion.div>
        </div>
      )}
    </AnimatePresence>
  );
};
