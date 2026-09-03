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
        obsidian: {
          canvas: "#08090B",
          surface: "#0F1115",
          subtle: "#14171D",
          elevated: "#1A1E26",
          highlight: "#222832",
          well: "#060709",
        },
        emerald: {
          DEFAULT: "#10B981",
          light: "#34D399",
          dark: "#059669",
          faint: "rgba(16, 185, 129, 0.12)",
        },
        amber: {
          studio: "#F59E0B",
        },
        ink: {
          primary: "#FFFFFF",
          secondary: "#A1A1AA",
          muted: "#71717A",
          faint: "#52525B",
        },
      },
      fontFamily: {
        sans: [
          "-apple-system",
          "BlinkMacSystemFont",
          '"SF Pro Display"',
          '"SF Pro Text"',
          "Inter",
          "system-ui",
          "sans-serif",
        ],
        serif: [
          '"Newsreader"',
          '"Source Serif Pro"',
          '"Charter"',
          "Georgia",
          "serif",
        ],
        mono: [
          '"SF Mono"',
          "ui-monospace",
          "Menlo",
          "Monaco",
          "Consolas",
          "monospace",
        ],
      },
      letterSpacing: {
        tighter: "-0.04em",
        tight: "-0.025em",
        eyebrow: "0.14em",
      },
      boxShadow: {
        tactile: "inset 0 1px 0 0 rgba(255, 255, 255, 0.08), 0 4px 12px rgba(0, 0, 0, 0.4)",
        console: "inset 0 1px 0 0 rgba(255, 255, 255, 0.12), 0 20px 50px -10px rgba(0, 0, 0, 0.8), 0 0 0 1px rgba(255, 255, 255, 0.08)",
        "tactile-btn": "inset 0 1px 0 0 rgba(255, 255, 255, 0.35), 0 2px 4px rgba(0, 0, 0, 0.3)",
        "inset-well": "inset 0 2px 5px 0 rgba(0, 0, 0, 0.6), inset 0 0 0 1px rgba(0, 0, 0, 0.4)",
      },
    },
  },
  plugins: [],
};

export default config;
