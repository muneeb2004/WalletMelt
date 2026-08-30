import React from 'react';
import { interpolate, Easing } from 'remotion';
import { PhoneScreen } from './PhoneScreen';

interface AndroidPhoneProps {
  frame: number;
  pushProgress?: number; // 0 (normal) to 1 (full viewport takeover)
}

export const AndroidPhone: React.FC<AndroidPhoneProps> = ({
  frame,
  pushProgress = 0,
}) => {
  // Base device dimensions (exact 1080:2400 aspect ratio for screen)
  const screenWidth = 360;
  const screenHeight = 800; // 360 / 800 = 0.45 (exact 1080 / 2400)
  const baseBezel = 6;

  // Bezel and hardware details fade out cleanly during the final push-in
  const hardwareDetailsOpacity = interpolate(pushProgress, [0.6, 0.95], [1, 0], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

  const activeBezel = baseBezel * hardwareDetailsOpacity;
  const outerWidth = screenWidth + activeBezel * 2;
  const outerHeight = screenHeight + activeBezel * 2;

  // Dynamic corner radius (interpolates to 0 during final takeover at frames 275-300)
  const screenRadius = interpolate(pushProgress, [0, 0.7, 1], [34, 16, 0], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: Easing.inOut(Easing.cubic),
  });

  const chassisRadius = interpolate(pushProgress, [0, 0.7, 1], [40, 20, 0], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

  // Dynamic specular edge highlight shifting with camera movement
  const specularAngle = interpolate(frame, [45, 105, 165, 210], [130, 115, 145, 135], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

  return (
    <div
      style={{
        position: 'relative',
        width: `${outerWidth}px`,
        height: `${outerHeight}px`,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
      }}
    >
      {/* Layered Physical Contact & Ambient Shadow */}
      {hardwareDetailsOpacity > 0 && (
        <div
          style={{
            position: 'absolute',
            inset: 0,
            borderRadius: `${chassisRadius}px`,
            opacity: hardwareDetailsOpacity,
            boxShadow: `
              0 30px 70px rgba(0, 0, 0, 0.75),
              0 60px 130px rgba(0, 0, 0, 0.50),
              0 15px 40px rgba(99, 102, 241, 0.08),
              0 0 20px rgba(0, 0, 0, 0.8)
            `,
            pointerEvents: 'none',
          }}
        />
      )}

      {/* Pixel Pro Outer Metallic Frame / Chassis */}
      <div
        style={{
          position: 'relative',
          width: '100%',
          height: '100%',
          borderRadius: `${chassisRadius}px`,
          padding: `${activeBezel}px`,
          boxSizing: 'border-box',
          // Premium dark polished titanium / obsidian chamfered bezel
          background:
            hardwareDetailsOpacity > 0
              ? `
            linear-gradient(
              ${specularAngle}deg,
              rgba(42, 46, 57, ${hardwareDetailsOpacity}) 0%,
              rgba(22, 25, 34, ${hardwareDetailsOpacity}) 20%,
              rgba(13, 15, 21, ${hardwareDetailsOpacity}) 50%,
              rgba(28, 32, 43, ${hardwareDetailsOpacity}) 80%,
              rgba(45, 50, 64, ${hardwareDetailsOpacity}) 100%
            )
          `
              : 'transparent',
          border:
            hardwareDetailsOpacity > 0
              ? `1.2px solid rgba(255, 255, 255, ${0.15 * hardwareDetailsOpacity})`
              : 'none',
          boxShadow:
            hardwareDetailsOpacity > 0
              ? `
            inset 0 1px 1px rgba(255, 255, 255, ${0.35 * hardwareDetailsOpacity}),
            inset 0 -1px 1px rgba(0, 0, 0, ${0.8 * hardwareDetailsOpacity}),
            0 0 0 1px rgba(0, 0, 0, ${0.9 * hardwareDetailsOpacity})
          `
              : 'none',
          overflow: 'hidden',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
        }}
      >
        {/* Inner Screen Container */}
        <div
          style={{
            position: 'relative',
            width: `${screenWidth}px`,
            height: `${screenHeight}px`,
            borderRadius: `${screenRadius}px`,
            overflow: 'hidden',
            backgroundColor: '#000000',
          }}
        >
          {/* Authentic WalletMelt Screen with Glass Overlay */}
          <PhoneScreen
            frame={frame}
            screenBorderRadius={screenRadius}
            reflectionOpacity={hardwareDetailsOpacity}
          />

          {/* Pixel-Style Centered Front Camera Punch Hole */}
          {hardwareDetailsOpacity > 0 && (
            <div
              style={{
                position: 'absolute',
                top: '12px',
                left: '50%',
                transform: 'translateX(-50%)',
                width: '11px',
                height: '11px',
                borderRadius: '50%',
                backgroundColor: '#050608',
                border: '1px solid #141720',
                boxShadow: '0 0 2px rgba(0, 0, 0, 0.8)',
                opacity: hardwareDetailsOpacity,
                zIndex: 30,
                pointerEvents: 'none',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
              }}
            >
              {/* Camera Lens Specular Highlight */}
              <div
                style={{
                  width: '3.5px',
                  height: '3.5px',
                  borderRadius: '50%',
                  backgroundColor: 'rgba(99, 102, 241, 0.45)',
                  boxShadow: 'inset 0 0 1px rgba(255, 255, 255, 0.6)',
                }}
              />
            </div>
          )}
        </div>
      </div>
    </div>
  );
};
