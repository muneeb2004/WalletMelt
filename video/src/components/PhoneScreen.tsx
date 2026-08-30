import React from 'react';
import { Img, staticFile, interpolate, Easing } from 'remotion';

interface PhoneScreenProps {
  frame: number;
  screenBorderRadius: number;
  reflectionOpacity?: number;
}

export const PhoneScreen: React.FC<PhoneScreenProps> = ({
  frame,
  screenBorderRadius,
  reflectionOpacity = 1,
}) => {
  // Glass reflection animation:
  // Starts slowly moving across screen during hero shot (105-165) and eases gracefully
  const reflectionOffset = interpolate(
    frame,
    [45, 105, 165, 230],
    [-80, -20, 60, 120],
    {
      extrapolateLeft: 'clamp',
      extrapolateRight: 'clamp',
      easing: Easing.inOut(Easing.quad),
    }
  );

  // Dynamic subtle sheen intensity
  const sheenAlpha = interpolate(
    frame,
    [45, 105, 140, 180, 270, 300],
    [0.0, 0.035, 0.045, 0.03, 0.015, 0.0],
    {
      extrapolateLeft: 'clamp',
      extrapolateRight: 'clamp',
    }
  );

  return (
    <div
      style={{
        position: 'relative',
        width: '100%',
        height: '100%',
        borderRadius: `${screenBorderRadius}px`,
        overflow: 'hidden',
        backgroundColor: '#000000',
        transform: 'translateZ(0)', // Force GPU layer
      }}
    >
      {/* Authentic WalletMelt Screenshot */}
      <Img
        src={staticFile('screenshots/01_dashboard_overview_dark.png')}
        style={{
          width: '100%',
          height: '100%',
          objectFit: 'cover',
          display: 'block',
        }}
      />

      {/* Subtle Cinematic Screen Glass Reflection */}
      <div
        style={{
          position: 'absolute',
          inset: '-50%',
          pointerEvents: 'none',
          opacity: reflectionOpacity,
          transform: `translate(${reflectionOffset}%, ${reflectionOffset * 0.4}%) rotate(-15deg)`,
          background: `
            linear-gradient(
              115deg,
              rgba(255, 255, 255, 0) 35%,
              rgba(255, 255, 255, ${sheenAlpha}) 48%,
              rgba(255, 255, 255, 0) 60%
            )
          `,
        }}
      />

      {/* Ultra-subtle Screen Edge Ambient Occlusion */}
      <div
        style={{
          position: 'absolute',
          inset: 0,
          borderRadius: `${screenBorderRadius}px`,
          pointerEvents: 'none',
          boxShadow: 'inset 0 0 4px rgba(0, 0, 0, 0.6)',
        }}
      />
    </div>
  );
};
