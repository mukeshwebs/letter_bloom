#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
SRC="$HOME/Desktop/LetterBloom_PlayStore_Assets/new_app_icon.png"
mkdir -p assets/icon

# Full launcher icon: clean 1024x1024 PNG (no alpha, with the dark navy bg).
magick "$SRC" -strip -resize 1024x1024^ -gravity center -extent 1024x1024 PNG24:assets/icon/app_icon.png

# Adaptive foreground: hex flower scaled to ~66% of canvas on transparent 1024x1024.
magick \( "$SRC" -strip -resize 680x680^ -gravity center -extent 680x680 \) \
       \( -size 1024x1024 xc:none \) \
       +swap -gravity center -composite \
       PNG32:assets/icon/app_icon_foreground.png

file assets/icon/app_icon.png assets/icon/app_icon_foreground.png
