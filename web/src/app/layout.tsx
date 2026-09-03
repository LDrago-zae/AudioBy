import type { Metadata, Viewport } from "next";
import "./globals.css";
import { AuthProvider } from "@/lib/auth-context";
import { ThemeProvider } from "@/lib/theme-context";

export const viewport: Viewport = {
  themeColor: [
    { media: "(prefers-color-scheme: dark)", color: "#08090B" },
    { media: "(prefers-color-scheme: light)", color: "#F8FAF8" },
  ],
  width: "device-width",
  initialScale: 1,
};

export const metadata: Metadata = {
  title: "AudioBy — Immersive Audiobooks & Document Narration",
  description:
    "Listen to 70,000+ public domain audiobooks and import your own PDFs with natural on-device and studio-grade neural voices. Available on iOS and Web.",
  openGraph: {
    title: "AudioBy — Immersive Audiobooks & Document Narration",
    description:
      "Listen to 70,000+ books and custom documents with studio-quality audio. Seamless cross-platform access.",
    type: "website",
    url: "https://audioby.app",
  },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" className="dark" suppressHydrationWarning>
      <head>
        <script
          dangerouslySetInnerHTML={{
            __html: `
              try {
                var saved = localStorage.getItem('audioby_theme');
                if (saved === 'light') {
                  document.documentElement.classList.remove('dark');
                  document.documentElement.classList.add('light');
                } else if (saved === 'dark') {
                  document.documentElement.classList.add('dark');
                  document.documentElement.classList.remove('light');
                } else if (window.matchMedia('(prefers-color-scheme: light)').matches) {
                  document.documentElement.classList.remove('dark');
                  document.documentElement.classList.add('light');
                }
              } catch (e) {}
            `,
          }}
        />
      </head>
      <body className="min-h-screen bg-[#F8FAF8] dark:bg-[#08090B] text-zinc-900 dark:text-white selection:bg-[#10B981] selection:text-black transition-colors duration-200">
        <ThemeProvider>
          <AuthProvider>{children}</AuthProvider>
        </ThemeProvider>
      </body>
    </html>
  );
}
