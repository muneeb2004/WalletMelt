import { bundle } from '@remotion/bundler';
import { renderStill, selectComposition } from '@remotion/renderer';
import path from 'path';
import fs from 'fs';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const entry = path.resolve(__dirname, '../src/index.ts');
const outDir = path.resolve(__dirname, '../../out');
const qaDir = path.resolve(outDir, 'qa');

fs.mkdirSync(qaDir, { recursive: true });

console.log('Bundling for QA stills...');
const bundleLocation = await bundle({
  entryPoint: entry,
});

const composition = await selectComposition({
  serveUrl: bundleLocation,
  id: 'WalletMeltPromo',
});

const qaFrames = [0, 45, 90, 150, 200, 240, 270, 299];
for (const frame of qaFrames) {
  const padded = String(frame).padStart(3, '0');
  const stillPath = path.resolve(qaDir, `frame-${padded}.png`);
  console.log(`Rendering frame ${frame} -> ${stillPath}...`);
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

console.log('All QA frames saved to:', qaDir);
