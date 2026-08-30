# WalletMelt Promotional Intro Video (Remotion)

A deterministic, high-production-value 10-second promotional intro video for **WalletMelt**, built programmatically using **Remotion**, **React**, **TypeScript**, and **Node.js**.

The video features authentic WalletMelt screenshots and brand assets, a custom Google Pixel Pro-class smartphone frame, cinematic camera movement, and a physical push-in transition to the first publication screenshot.

---

## 📁 Directory Structure

```text
video/
├── package.json               # Dependencies and build/render scripts
├── tsconfig.json              # TypeScript configuration
├── remotion.config.ts         # Remotion render settings (1080p, H.264, CRF 16)
├── README.md                  # Documentation and commands
├── scripts/
│   ├── render-all.mjs         # Programmatic renderer for video and QA stills
│   └── render-qa.mjs          # QA stills renderer
├── src/
│   ├── index.ts               # Remotion root registration
│   ├── Root.tsx               # Composition registry
│   ├── WalletMeltPromo.tsx    # Main orchestration composition (300 frames / 10s)
│   ├── styles.css             # Typography and global styling
│   └── components/
│       ├── CinematicBackground.tsx   # Studio backdrop and lighting
│       ├── AndroidPhone.tsx          # Pixel Pro-class device modeling
│       ├── PhoneScreen.tsx           # Screen mask and glass reflection
│       └── BrandReveal.tsx           # Authentic WalletMelt branding reveal
└── public/
    ├── screenshots/           # Authentic app screenshots
    ├── branding/              # Authentic brand logos and icons
    └── fonts/                 # Plus Jakarta Sans variable font
```

---

## 🎬 Video Specifications

* **Composition ID**: `WalletMeltPromo`
* **Resolution**: 1920 × 1080 (16:9 widescreen)
* **Frame Rate**: 30 FPS
* **Duration**: 10 seconds (300 frames)
* **Codec**: H.264 (MP4 container)
* **Output**: `out/walletmelt-promo.mp4`

---

## ⏱️ Exact Timeline (300 Frames)

| Frame Range | Phase | Description |
|---|---|---|
| **0 – 44** | **Black / Ambient Intro** | Pure OLED black gently warming into subtle studio ambient lighting. |
| **45 – 104** | **Phone Reveal** | Google Pixel Pro device emerges with smooth cubic easing (`opacity: 0 → 1`, `scale: 0.94 → 1.0`, `translateY: 25px → 0`, `rotateY: -8° → -2°`). |
| **105 – 164** | **Hero Product Shot** | Subtle cinematic 3D camera pan (`rotateY: -2° → 3°`, `rotateX: 1.5° → -1.0°`) with an ultra-subtle animated glass reflection gliding across the screen. |
| **165 – 209** | **Brand Reveal** | Authentic WalletMelt icon and typography smoothly reveal above the device. |
| **210 – 269** | **Camera Push-In** | Physical camera push toward the phone screen; bezels expand toward viewport edges. |
| **270 – 300** | **Screen Takeover Match Cut** | Seamless push-in through display boundaries; bezels and reflections exit; the screen becomes 100% of the canvas at frame 300 in native aspect ratio. |

---

## 🚀 Commands

### 1. Install Dependencies
```bash
cd video
npm install
```

### 2. Launch Remotion Studio (Interactive Preview & Playback)
```bash
npm run dev
# or
npm run preview
```

### 3. Typecheck
```bash
npm run typecheck
```

### 4. Render the Full MP4 Video & QA Stills
```bash
npm run render
```

### 5. Render Only QA Stills
```bash
npm run render:qa
```

---

## 🔍 QA Deliverables

The output directory contains:
- `out/walletmelt-promo.mp4`: Full 1080p promotional video
- `out/qa/frame-000.png`: Black intro state (Frame 0)
- `out/qa/frame-045.png`: Ambient environment emergence (Frame 45)
- `out/qa/frame-090.png`: Phone reveal hero state (Frame 90)
- `out/qa/frame-150.png`: 3D orbit & subtle glass reflection (Frame 150)
- `out/qa/frame-200.png`: WalletMelt authentic brand reveal (Frame 200)
- `out/qa/frame-240.png`: Camera push-in acceleration (Frame 240)
- `out/qa/frame-270.png`: Viewport screen expansion (Frame 270)
- `out/qa/frame-299.png`: Seamless match-cut publication frame (Frame 299)
