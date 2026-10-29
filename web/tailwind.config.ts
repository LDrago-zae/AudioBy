import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./src/pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/components/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  darkMode: "class",
  theme: {
    extend: {
      screens: {
        xs: "480px",
      },
      colors: {
        leaf: {
          canvas: "var(--background)",
          surface: "var(--surface)",
          raised: "var(--surface-raised)",
          ink: "var(--foreground)",
          muted: "var(--ink-muted)",
          faint: "var(--ink-faint)",
          field: "var(--field)",
        },
        emerald: {
          DEFAULT: "#10B981",
          light: "#34D399",
          dark: "#059669",
          faint: "rgba(16, 185, 129, 0.12)",
          ink: "#042F1E",
        },
      },
      fontFamily: {
        display: ["var(--font-display)", "ui-sans-serif", "system-ui", "sans-serif"],
        body: ["var(--font-body)", "ui-sans-serif", "system-ui", "sans-serif"],
        sans: ["var(--font-body)", "ui-sans-serif", "system-ui", "sans-serif"],
      },
      letterSpacing: {
        tighter: "-0.04em",
        tight: "-0.025em",
      },
      boxShadow: {
        lift: "0 18px 40px -24px rgba(4, 47, 30, 0.45)",
        soft: "0 8px 24px -16px rgba(4, 47, 30, 0.35)",
      },
      maxWidth: {
        measure: "70ch",
      },
    },
  },
  plugins: [],
};

export default config;
