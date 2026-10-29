import sharp from "sharp";
import { writeFileSync, mkdirSync } from "fs";
import { dirname, join } from "path";
import { fileURLToPath } from "url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const root = join(__dirname, "../..");
const web = join(__dirname, "..");

const EMERALD = "#10B981";
const INK = "#042F1E";

/**
 * Manga speech bubble + rising sonic bars (even-odd holes).
 * Reads as manga dialogue + audio narration at app-icon size.
 */
export const MARK_PATH =
  // Bubble body
  "M5 4.2h22c2.1 0 3.8 1.7 3.8 3.8v11.2c0 2.1-1.7 3.8-3.8 3.8H14.2L8.2 29.2 9.6 23H5c-2.1 0-3.8-1.7-3.8-3.8V8c0-2.1 1.7-3.8 3.8-3.8z" +
  // Sonic bars
  "M9.6 10.4h3v8.6h-3v-8.6z" +
  "M14.5 8.2h3v10.8h-3V8.2z" +
  "M19.4 9.5h3v9.5h-3V9.5z";

function appIconSvg(size = 1024) {
  const pad = size * 0.16;
  const mark = size - pad * 2;
  const scale = mark / 32;
  return `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 ${size} ${size}">
  <rect width="${size}" height="${size}" fill="${EMERALD}"/>
  <g transform="translate(${pad} ${pad}) scale(${scale})">
    <path fill="${INK}" fill-rule="evenodd" d="${MARK_PATH}"/>
  </g>
</svg>`;
}

function faviconSvg(size = 512) {
  const pad = size * 0.14;
  const mark = size - pad * 2;
  const scale = mark / 32;
  const r = size * 0.22;
  return `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 ${size} ${size}">
  <rect width="${size}" height="${size}" rx="${r}" fill="${EMERALD}"/>
  <g transform="translate(${pad} ${pad}) scale(${scale})">
    <path fill="${INK}" fill-rule="evenodd" d="${MARK_PATH}"/>
  </g>
</svg>`;
}

async function main() {
  writeFileSync(
    join(web, "public/mark.svg"),
    `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32" fill="currentColor" aria-hidden="true">
  <path fill-rule="evenodd" d="${MARK_PATH}"/>
</svg>
`
  );

  writeFileSync(
    join(web, "src/components/AudioByMark.tsx"),
    `/** Manga speech bubble + sonic bars — even-odd fill. */
const MARK_PATH =
  "${MARK_PATH}";

export function AudioByMark({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 32 32" className={className} fill="currentColor" aria-hidden="true">
      <path fillRule="evenodd" d={MARK_PATH} />
    </svg>
  );
}
`
  );

  const appIconPath = join(
    root,
    "AudioBy/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
  );
  const webIconPath = join(web, "src/app/icon.png");
  const previewPath = join(web, "public/mark-preview.png");
  mkdirSync(dirname(appIconPath), { recursive: true });

  await sharp(Buffer.from(appIconSvg(1024))).png().toFile(appIconPath);
  await sharp(Buffer.from(faviconSvg(512))).png().toFile(webIconPath);
  await sharp(Buffer.from(appIconSvg(512))).png().toFile(previewPath);

  console.log("Rendered speech-bubble mark");
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
