"use client";

import React, { useEffect, useRef } from "react";
import { useTheme } from "@/lib/theme-context";

interface WaveformVisualizerProps {
  isPlaying: boolean;
  barCount?: number;
  height?: number;
  className?: string;
  accent?: string;
}

export const WaveformVisualizer: React.FC<WaveformVisualizerProps> = ({
  isPlaying,
  barCount = 36,
  height = 40,
  className = "",
  accent,
}) => {
  const canvasRef = useRef<HTMLCanvasElement | null>(null);
  const { isDark } = useTheme();

  const activeColor = accent || (isDark ? "#3BE382" : "#0F9B51");
  const idleColor = isDark ? "rgba(255, 255, 255, 0.16)" : "rgba(0, 0, 0, 0.12)";

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    let animationId: number;
    let phase = 0;

    const render = () => {
      const dpr = window.devicePixelRatio || 1;
      const width = canvas.clientWidth;
      const h = canvas.clientHeight;

      if (canvas.width !== width * dpr || canvas.height !== h * dpr) {
        canvas.width = width * dpr;
        canvas.height = h * dpr;
      }

      ctx.save();
      ctx.scale(dpr, dpr);
      ctx.clearRect(0, 0, width, h);

      const spacing = 3;
      const totalSpacing = spacing * (barCount - 1);
      const barWidth = Math.max(2, (width - totalSpacing) / barCount);
      const midY = h / 2;

      phase += isPlaying ? 0.08 : 0.02;

      for (let i = 0; i < barCount; i++) {
        const x = i * (barWidth + spacing);

        let amplitude: number;
        if (isPlaying) {
          // Dynamic multi-frequency sine wave simulating vocal speech
          const wave1 = Math.sin(phase + i * 0.35);
          const wave2 = Math.cos(phase * 1.4 + i * 0.2);
          const wave3 = Math.sin(phase * 0.7 + i * 0.55);
          const raw = (wave1 * 0.5 + wave2 * 0.3 + wave3 * 0.2 + 1) / 2;
          amplitude = Math.max(0.12, raw * 0.95);
        } else {
          // Idle gentle breathing wave
          const idle = (Math.sin(phase + i * 0.15) + 1) / 2;
          amplitude = 0.08 + idle * 0.12;
        }

        const barHeight = Math.max(4, amplitude * (h - 6));
        const y = midY - barHeight / 2;

        ctx.fillStyle = isPlaying ? activeColor : idleColor;

        // Rounded bar
        ctx.beginPath();
        const r = Math.min(barWidth / 2, 2);
        ctx.roundRect(x, y, barWidth, barHeight, [r, r, r, r]);
        ctx.fill();
      }

      ctx.restore();
      animationId = requestAnimationFrame(render);
    };

    render();

    return () => {
      cancelAnimationFrame(animationId);
    };
  }, [isPlaying, barCount, activeColor, idleColor]);

  return (
    <canvas
      ref={canvasRef}
      style={{ height: `${height}px` }}
      className={`w-full block ${className}`}
    />
  );
};
