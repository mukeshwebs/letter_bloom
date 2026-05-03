#!/usr/bin/env bash
# tools/firebase_setup.sh
#
# One-command Firebase setup for LetterBloom.
#
# What it does (in order):
#   1. Verifies prerequisites (firebase, dart).
#   2. firebase login   (opens browser → sign in as mukeshone045@gmail.com).
#   3. Creates project  letterbloom-<random> (or reuses LB_PROJECT_ID env).
#   4. Enables Firestore in NATIVE mode (region: us-central).
#   5. Enables Anonymous auth.
#   6. Installs flutterfire CLI if missing, then runs `flutterfire configure`
#      (writes lib/firebase_options.dart with real values).
#   7. Pushes Firestore rules (firestore.rules).
#   8. Seeds the dictionary by running tools/seed_words.dart (uploads chunks).
#   9. Optionally builds & deploys the web build to Firebase Hosting.
#
# Environment variables (optional):
#   LB_PROJECT_ID        Reuse an existing project id instead of creating one.
#   LB_DEPLOY=1          Build web + firebase deploy --only hosting at the end.
#   LB_SKIP_SEED=1       Skip the dictionary upload (rerun later with seed_words.dart).
#
# Run from the project root:
#   bash tools/firebase_setup.sh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

bold()   { printf "\033[1m%s\033[0m\n" "$*"; }
green()  { printf "\033[32m%s\033[0m\n" "$*"; }
yellow() { printf "\033[33m%s\033[0m\n" "$*"; }
red()    { printf "\033[31m%s\033[0m\n" "$*" 1>&2; }

step() { echo; bold "==> $*"; }

# ---------- 1. Prerequisites ----------
step "1. Checking prerequisites"
command -v firebase >/dev/null || { red "firebase CLI missing. Install: https://firebase.google.com/docs/cli"; exit 1; }
command -v dart    >/dev/null || { red "dart missing (install Flutter SDK and re-run)"; exit 1; }
command -v flutter >/dev/null || { red "flutter missing"; exit 1; }
green "OK: firebase $(firebase --version), dart $(dart --version 2>&1 | head -1)"

# ---------- 2. Login ----------
step "2. firebase login"
firebase login --no-localhost || firebase login

ACCOUNT=$(firebase login:list 2>&1 | grep -oE '[A-Za-z0-9._-]+@[A-Za-z0-9.-]+' | head -1 || true)
green "Logged in as: ${ACCOUNT:-unknown}"

# ---------- 3. Project ----------
step "3. Project"
if [ -n "${LB_PROJECT_ID:-}" ]; then
  PROJECT_ID="$LB_PROJECT_ID"
  yellow "Reusing existing project: $PROJECT_ID"
else
  SUFFIX=$(LC_ALL=C tr -dc 'a-z0-9' </dev/urandom | head -c 6)
  PROJECT_ID="letterbloom-$SUFFIX"
  yellow "Creating project: $PROJECT_ID"
  firebase projects:create "$PROJECT_ID" --display-name "LetterBloom"
fi
firebase use "$PROJECT_ID"

# ---------- 4. Firestore ----------
step "4. Enabling Firestore (native mode, region us-central)"
firebase firestore:databases:create '(default)' --location us-central --project "$PROJECT_ID" 2>/dev/null \
  || yellow "Firestore database already exists (skipping create)"

# ---------- 5. Anonymous auth ----------
step "5. Enabling Anonymous auth"
yellow "Anonymous sign-in must be toggled ON in the console once:"
yellow "  https://console.firebase.google.com/project/$PROJECT_ID/authentication/providers"
read -rp "Press <Enter> after enabling Anonymous auth in the console... "

# ---------- 6. flutterfire configure ----------
step "6. Running flutterfire configure"
if ! command -v flutterfire >/dev/null; then
  yellow "Installing flutterfire CLI..."
  dart pub global activate flutterfire_cli
  export PATH="$PATH:$HOME/.pub-cache/bin"
fi
flutterfire configure \
  --project "$PROJECT_ID" \
  --platforms=web,android,ios \
  --yes \
  --out lib/firebase_options.dart

green "lib/firebase_options.dart written."

# ---------- 7. Firestore rules ----------
step "7. Deploying Firestore rules + indexes"
firebase deploy --only firestore:rules --project "$PROJECT_ID"

# ---------- 8. Seed words ----------
if [ "${LB_SKIP_SEED:-0}" != "1" ]; then
  step "8. Seeding dictionary (this uploads ~105k words in chunks)"
  flutter pub get
  dart run tools/seed_words.dart "$PROJECT_ID"
else
  yellow "Skipped seeding (LB_SKIP_SEED=1)."
fi

# ---------- 9. Hosting ----------
if [ "${LB_DEPLOY:-0}" = "1" ]; then
  step "9. Building web + deploying to Firebase Hosting"
  flutter build web --release
  if [ ! -f firebase.json ]; then
    cat > firebase.json <<'JSON'
{
  "hosting": {
    "public": "build/web",
    "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
    "rewrites": [{ "source": "**", "destination": "/index.html" }]
  }
}
JSON
  fi
  firebase deploy --only hosting --project "$PROJECT_ID"
  green "Deployed → https://$PROJECT_ID.web.app"
  echo "Update lib/services/storage.dart shareUrl default OR call storage.setShareUrl()."
fi

echo
green "✅ All done. Project: $PROJECT_ID"
echo "Console: https://console.firebase.google.com/project/$PROJECT_ID"
