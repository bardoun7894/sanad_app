#!/usr/bin/env bash
# Compose App Store screenshots with headless Chrome (Arabic shaping needs a browser).
# Usage: app-store-assets/compose.sh <manifest.tsv>
# Manifest columns (tab separated): out.png  width  height  raw-image  caption  sub-caption  dir
# Paths are relative to app-store-assets/.
set -euo pipefail
cd "$(dirname "$0")"
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
manifest="$1"
while IFS=$'\t' read -r out w h img t s dir; do
  [[ -z "$out" || "$out" == \#* ]] && continue
  mkdir -p "$(dirname "$out")"
  url=$(node -e 'const [f,i,t,s,d]=process.argv.slice(1);const q=new URLSearchParams({img:i,t,s,dir:d});console.log("file://"+f+"?"+q.toString())' "$PWD/composer.html" "$img" "$t" "$s" "$dir")
  "$CHROME" --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=1 \
    --allow-file-access-from-files --virtual-time-budget=8000 \
    --window-size="$w,$h" --screenshot="$PWD/$out" "$url" >/dev/null 2>&1
  # Apple rejects PNGs with alpha; flatten to RGB.
  magick "$out" -alpha off -resize "${w}x${h}!" "$out"
  echo "$out $(magick identify -format '%wx%h' "$out")"
done < "$manifest"
