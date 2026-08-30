import React from 'react';
import { Img, staticFile, interpolate, Easing } from 'remotion';

interface BrandRevealProps {
  frame: number;
}

export const BrandReveal: React.FC<BrandRevealProps> = ({ frame }) => {
  // Entrance between frames 165 and 185 (20 frames)
  const enterOpacity = interpolate(frame, [165, 185], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: Easing.out(Easing.cubic),
  });

  const enterTranslateY = interpolate(frame, [165, 185], [12, 0], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: Easing.out(Easing.cubic),
  });

  const enterScale = interpolate(frame, [165, 185], [0.96, 1.0], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: Easing.out(Easing.cubic),
  });

  // Exit / Fade as camera push accelerates (frames 210 to 240)
  const exitOpacity = interpolate(frame, [210, 235], [1, 0], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: Easing.in(Easing.cubic),
  });

  const exitTranslateY = interpolate(frame, [210, 235], [0, -18], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

  const totalOpacity = frame < 165 ? 0 : enterOpacity * exitOpacity;
  const currentTranslateY = frame < 210 ? enterTranslateY : exitTranslateY;
  const currentScale = enterScale;

  if (totalOpacity <= 0) {
    return null;
  }

  return (
    <div
      style={{
        position: 'absolute',
        top: '42px',
        left: '50%',
        transform: `translateX(-50%) translateY(${currentTranslateY}px) scale(${currentScale})`,
        opacity: totalOpacity,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        gap: '12px',
        zIndex: 25,
        pointerEvents: 'none',
      }}
    >
      {/* Authentic WalletMelt Melting-Wallet Icon */}
      <Img
        src={staticFile('branding/walletmelt_main_logo_transparent.png')}
        style={{
          height: '42px',
          width: '42px',
          objectFit: 'contain',
          filter: 'drop-shadow(0 4px 12px rgba(0, 0, 0, 0.7)) drop-shadow(0 0 16px rgba(99, 102, 241, 0.25))',
        }}
      />

      {/* Official WalletMelt Brand Typography in PlusJakartaSans */}
      <span
        style={{
          fontFamily: "'PlusJakartaSans', sans-serif",
          fontSize: '27px',
          fontWeight: 800,
          letterSpacing: '-0.5px',
          color: '#F8FAFC',
          textShadow: '0 2px 10px rgba(0, 0, 0, 0.8), 0 0 20px rgba(99, 102, 241, 0.2)',
          lineHeight: 1,
        }}
      >
        WalletMelt
      </span>
    </div>
  );
};
