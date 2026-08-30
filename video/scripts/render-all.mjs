import { bundle } from '@remotion/bundler';
import { renderMedia, renderStill, selectComposition } from '@remotion/renderer';
import path from 'path';
import fs from 'fs';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const entry = path.resolve(__dirname, '../src/index.ts');
const outDir = path.resolve(__dirname, '../../out');
const qaDir = path.resolve(outDir, 'qa');

// Ensure output directories exist
fs.mkdirSync(outDir, { recursive: true });
fs.mkdirSync(qaDir, { recursive: true });

console.log('--- 1. Bundling Remotion project ---');
const bundleLocation = await bundle({
  entryPoint: entry,
});
console.log('Bundle created at:', bundleLocation);

console.log('--- 2. Selecting Composition: WalletMeltPromo ---');
const composition = await selectComposition({
  serveUrl: bundleLocation,
  id: 'WalletMeltPromo',
});
console.log('Composition specs:', {
  id: composition.id,
  width: composition.width,
  height: composition.height,
  fps: composition.fps,
  durationInFrames: composition.durationInFrames,
});

console.log('--- 3. Rendering QA Still Frames ---');
const qaFrames = [0, 45, 90, 150, 200, 240, 270, 299];
for (const frame of qaFrames) {
  const padded = String(frame).padStart(3, '0');
  const stillPath = path.resolve(qaDir, `frame-${padded}.png`);
  console.log(`Rendering still frame ${frame} -> ${stillPath}...`);
  await renderStill({
    composition,
    serveUrl: bundleLocation,
    output: stillPath,
    frame,
    imageFormat: 'png',
    overwrite: true,
  });
  console.log(`✓ Saved frame-${padded}.png`);
}

console.log('--- 4. Rendering Full MP4 Video ---');
const videoOutPath = path.resolve(outDir, 'walletmelt-promo.mp4');
console.log(`Rendering 10s video (300 frames) -> ${videoOutPath}...`);

let lastProgress = 0;
await renderMedia({
  composition,
  serveUrl: bundleLocation,
  codec: 'h264',
  outputLocation: videoOutPath,
  overwrite: true,
  onProgress: ({ renderedFrames, encodedFrames, progress }) => {
    const p = Math.floor(progress * 100);
    if (p >= lastProgress + 10) {
      lastProgress = p;
      console.log(`Rendering progress: ${p}% (${renderedFrames}/${composition.durationInFrames} frames)`);
    }
  },
});

console.log('✓ Video rendering complete:', videoOutPath);
