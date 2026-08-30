import React from 'react';
import { AbsoluteFill, interpolate, Easing } from 'remotion';

interface CinematicBackgroundProps {
  frame: number;
}

export const CinematicBackground: React.FC<CinematicBackgroundProps> = ({ frame }) => {
  // Frames 0–15: Pure black
  // Frames 15–45: Ambient studio illumination softly emerges
  const enterAmbientOpacity = interpolate(frame, [15, 45], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: Easing.out(Easing.cubic),
  });

  // Frames 240–295: Fade ambient light down to pure OLED black for seamless match cut
  const exitAmbientOpacity = interpolate(frame, [240, 290], [1, 0], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: Easing.inOut(Easing.cubic),
  });

  const ambientOpacity = enterAmbientOpacity * exitAmbientOpacity;

  // Background subtly expands during camera push (210–300)
  const bgScale = interpolate(frame, [210, 300], [1.0, 1.15], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: Easing.inOut(Easing.cubic),
  });

  return (
    <AbsoluteFill
      style={{
        backgroundColor: '#000000',
        overflow: 'hidden',
      }}
    >
      {/* Primary Ambient Studio Illumination */}
      <div
        style={{
          position: 'absolute',
          inset: '-20%',
          opacity: ambientOpacity,
          transform: `scale(${bgScale})`,
          background: `
            radial-gradient(
              circle at 50% 45%,
              rgba(99, 102, 241, 0.05) 0%,
              rgba(20, 23, 34, 0.6) 35%,
              rgba(12, 14, 20, 0.9) 60%,
              rgba(0, 0, 0, 1.0) 90%
            )
          `,
        }}
      />

      {/* Secondary Soft Rim Light / Studio Depth */}
      <div
        style={{
          position: 'absolute',
          inset: 0,
          opacity: ambientOpacity * 0.7,
          background: `
            radial-gradient(
              ellipse at 50% 25%,
              rgba(255, 255, 255, 0.02) 0%,
              rgba(99, 102, 241, 0.02) 40%,
              transparent 70%
            )
          `,
        }}
      />

      {/* Subtle Studio Vignette */}
      <div
        style={{
          position: 'absolute',
          inset: 0,
          opacity: ambientOpacity,
          background: `
            radial-gradient(
              circle at 50% 50%,
              transparent 45%,
              rgba(0, 0, 0, 0.8) 100%
            )
          `,
          pointerEvents: 'none',
        }}
      />
    </AbsoluteFill>
  );
};
