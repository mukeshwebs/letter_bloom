#!/usr/bin/env bash
# Regenerate launcher icons from assets/icon/app_icon.png
# Required source files:
#   assets/icon/app_icon.png             (1024x1024, full icon w/ background)
#   assets/icon/app_icon_foreground.png  (1024x1024, transparent, padded logo)
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ ! -f assets/icon/app_icon.png ]]; then
  echo "ERROR: assets/icon/app_icon.png missing. Save the LetterBloom 1024x1024 PNG there first."
  exit 1
fi
if [[ ! -f assets/icon/app_icon_foreground.png ]]; then
  echo "ERROR: assets/icon/app_icon_foreground.png missing (1024x1024, transparent bg, padded)."
  exit 1
fi

flutter pub get
dart run flutter_launcher_icons
echo "Done. Verify: android/app/src/main/res/mipmap-*/ic_launcher.png"
