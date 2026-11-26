#!/usr/bin/env bash
# Capture raw App Store screens from a booted simulator.
# Usage: app-store-assets/capture.sh <sim-udid> <ar|en> <device-label> ["chat prompt"]
# Credentials come from ~/.config/sanad/screenshot-account.txt (scripts/create-screenshot-demo-account.js).
# Raw PNGs land in app-store-assets/raw/<lang>-<device-label>/<name>.png
set -uo pipefail
cd "$(dirname "$0")/.."
UDID=$1; LANG_CODE=$2; LABEL=$3; PROMPT=${4:-}
CRED=~/.config/sanad/screenshot-account.txt
EMAIL=$(sed -n 1p "$CRED"); PASS=$(sed -n 2p "$CRED")
OUT="app-store-assets/raw/$LANG_CODE-$LABEL"; mkdir -p "$OUT"
xcrun simctl status_bar "$UDID" override --time 9:41 --dataNetwork wifi --wifiMode active \
  --wifiBars 3 --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/store_screenshots_test.dart -d "$UDID" \
  --dart-define=SHOT_EMAIL="$EMAIL" --dart-define=SHOT_PASSWORD="$PASS" \
  --dart-define=SHOT_LANG="$LANG_CODE" --dart-define=SHOT_CHAT="$PROMPT" 2>&1 |
while IFS= read -r line; do
  echo "$line"
  if [[ "$line" == *SHOT:* ]]; then
    name=${line##*SHOT:}; name=${name//[^a-z0-9_-]/}
    xcrun simctl io "$UDID" screenshot "$OUT/$name.png" >/dev/null 2>&1 && echo "CAPTURED $OUT/$name.png"
  fi
done
