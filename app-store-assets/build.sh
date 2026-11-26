#!/usr/bin/env bash
# Build final App Store screenshots from raw captures + captions.tsv.
# Usage: app-store-assets/build.sh <ar|en> <raw-label> <iphone|ipad>
#   iphone -> out/<lang>/iphone69/NN.png (1320x2868) and out/<lang>/iphone65/NN.png (1284x2778)
#   ipad   -> out/<lang>/ipad13/NN.png (2064x2752)
set -euo pipefail
cd "$(dirname "$0")"
LANG_CODE=$1; RAW=$2; KIND=$3
if [ "$LANG_CODE" = ar ]; then DIR=rtl; TCOL=3; SCOL=4; else DIR=ltr; TCOL=5; SCOL=6; fi
if [ "$KIND" = ipad ]; then SIZES="ipad13:2064:2752"; else SIZES="iphone69:1320:2868 iphone65:1284:2778"; fi
manifest=$(mktemp)
while IFS=$'\t' read -r -a f; do
  [[ -z "${f[0]:-}" || "${f[0]}" == \#* ]] && continue
  img="raw/$RAW/${f[1]}.png"; [ -f "$img" ] || { echo "skip missing $img" >&2; continue; }
  for s in $SIZES; do
    IFS=: read -r label w h <<<"$s"
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "out/$LANG_CODE/$label/0${f[0]}.png" "$w" "$h" "$img" \
      "${f[$((TCOL-1))]}" "${f[$((SCOL-1))]}" "$DIR" >> "$manifest"
  done
done < captions.tsv
./compose.sh "$manifest"
rm -f "$manifest"
