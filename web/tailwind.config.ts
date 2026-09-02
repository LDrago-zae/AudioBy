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
        canvas: "#0C100E",
        surface: {
          DEFAULT: "#121714",
          subtle: "#161D19",
          elevated: "#1B231E",
          highlight: "#242E28",
        },
        border: {
          DEFAULT: "#232D27",
          subtle: "rgba(255, 255, 255, 0.07)",
          focus: "rgba(59, 227, 130, 0.4)",
        },
        emerald: {
          DEFAULT: "#3BE382",
          light: "#62FFA4",
          dark: "#0F9B51",
          glow: "rgba(59, 227, 130, 0.12)",
        },
        ink: {
          primary: "#F3F5F4",
          secondary: "#9EAA9F",
          muted: "#667268",
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
        eyebrow: "0.18em",
      },
      boxShadow: {
        card: "0 1px 2px rgba(0, 0, 0, 0.6), 0 0 0 1px rgba(255, 255, 255, 0.05)",
        elevated: "0 8px 30px rgba(0, 0, 0, 0.7), 0 0 0 1px rgba(255, 255, 255, 0.08)",
        glow: "0 0 40px rgba(59, 227, 130, 0.15)",
      },
    },
  },
  plugins: [],
};

export default config;
