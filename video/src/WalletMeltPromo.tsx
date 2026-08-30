import React from 'react';
import {
  AbsoluteFill,
  interpolate,
  useCurrentFrame,
  Easing,
} from 'remotion';
import { CinematicBackground } from './components/CinematicBackground';
import { AndroidPhone } from './components/AndroidPhone';
import { BrandReveal } from './components/BrandReveal';

export const WalletMeltPromo: React.FC = () => {
  const frame = useCurrentFrame();

  // ── 01. PHASE: 0–44 FRAMES (BLACK / AMBIENT INTRO) ───────────────────
  // Handled inside CinematicBackground (ambient light emerges 15-44)

  // ── 02. PHASE: 45–104 FRAMES (PHONE REVEAL) ──────────────────────────
  const revealOpacity = interpolate(frame, [45, 80], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: Easing.out(Easing.cubic),
  });

  const revealTranslateY = interpolate(frame, [45, 104], [25, 0], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: Easing.out(Easing.cubic),
  });

  const revealScale = interpolate(frame, [45, 104], [0.94, 1.0], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: Easing.out(Easing.cubic),
  });

  const revealRotateY = interpolate(frame, [45, 104], [-8, -2], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: Easing.out(Easing.cubic),
  });

  const revealRotateX = interpolate(frame, [45, 104], [2.0, 1.5], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: Easing.out(Easing.cubic),
  });

  // ── 03. PHASE: 105–164 FRAMES (HERO PRODUCT SHOT) ────────────────────
  const heroRotateY = interpolate(frame, [105, 164], [-2, 3], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: Easing.inOut(Easing.quad),
  });

  const heroRotateX = interpolate(frame, [105, 164], [1.5, -1.0], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: Easing.inOut(Easing.quad),
  });

  const heroTranslateX = interpolate(frame, [105, 164], [0, 4], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: Easing.inOut(Easing.quad),
  });

  // ── 04. PHASE: 165–209 FRAMES (BRAND REVEAL & SQUARE UP) ─────────────
  const brandPhaseRotateY = interpolate(frame, [165, 209], [3, 0], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: Easing.inOut(Easing.quad),
  });

  const brandPhaseRotateX = interpolate(frame, [165, 209], [-1.0, 0], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: Easing.inOut(Easing.quad),
  });

  const brandPhaseTranslateX = interpolate(frame, [165, 209], [4, 0], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: Easing.inOut(Easing.quad),
  });

  // ── 05. PHASE: 210–300 FRAMES (CAMERA PUSH & MATCH CUT TAKEOVER) ─────
  const pushProgress = interpolate(frame, [210, 300], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: Easing.inOut(Easing.cubic),
  });

  // Scale target: 1080 (canvas height) / 800 (screen base height) = 1.35
  const pushScale = interpolate(pushProgress, [0, 1], [1.0, 1.35], {
    easing: Easing.inOut(Easing.cubic),
  });

  // ── CALCULATE COMBINED 3D TRANSFORM ──────────────────────────────────
  let phoneOpacity = 0;
  let phoneScale = 1;
  let phoneTranslateX = 0;
  let phoneTranslateY = 0;
  let phoneRotateY = 0;
  let phoneRotateX = 0;

  if (frame < 45) {
    phoneOpacity = 0;
  } else if (frame <= 104) {
    phoneOpacity = revealOpacity;
    phoneScale = revealScale;
    phoneTranslateX = 0;
    phoneTranslateY = revealTranslateY;
    phoneRotateY = revealRotateY;
    phoneRotateX = revealRotateX;
  } else if (frame <= 164) {
    phoneOpacity = 1;
    phoneScale = 1.0;
    phoneTranslateX = heroTranslateX;
    phoneTranslateY = 0;
    phoneRotateY = heroRotateY;
    phoneRotateX = heroRotateX;
  } else if (frame <= 209) {
    phoneOpacity = 1;
    phoneScale = 1.0;
    phoneTranslateX = brandPhaseTranslateX;
    phoneTranslateY = 0;
    phoneRotateY = brandPhaseRotateY;
    phoneRotateX = brandPhaseRotateX;
  } else {
    // 210–300 (Camera Push)
    phoneOpacity = 1;
    phoneScale = pushScale;
    phoneTranslateX = 0;
    phoneTranslateY = 0;
    phoneRotateY = 0;
    phoneRotateX = 0;
  }

  return (
    <AbsoluteFill
      style={{
        backgroundColor: '#000000',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        perspective: '1400px',
        overflow: 'hidden',
      }}
    >
      {/* 1. Cinematic Studio Background */}
      <CinematicBackground frame={frame} />

      {/* 2. Authentic Brand Reveal Layer */}
      <BrandReveal frame={frame} />

      {/* 3. Android Pixel Pro Device Composition */}
      {phoneOpacity > 0 && (
        <div
          style={{
            transformStyle: 'preserve-3d',
            transform: `
              translateX(${phoneTranslateX}px)
              translateY(${phoneTranslateY}px)
              scale(${phoneScale})
              rotateY(${phoneRotateY}deg)
              rotateX(${phoneRotateX}deg)
            `,
            opacity: phoneOpacity,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            willChange: 'transform, opacity',
          }}
        >
          <AndroidPhone frame={frame} pushProgress={pushProgress} />
        </div>
      )}
    </AbsoluteFill>
  );
};
