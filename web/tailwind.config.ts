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
          DEFAULT: "#EB5E28",
          light: "#EB5E28",
          dark: "#BA5026",
          faint: "rgba(235, 94, 40, 0.12)",
          ink: "#252422",
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
        lift: "0 18px 40px -24px rgba(37, 36, 34, 0.45)",
        soft: "0 8px 24px -16px rgba(37, 36, 34, 0.35)",
      },
      maxWidth: {
        measure: "70ch",
      },
    },
  },
  plugins: [],
};

export default config;
