#!/bin/zsh

# ci_post_clone.sh — Xcode Cloud post-clone script for PayKey (Flutter/iOS)
#
# Build triggering is controlled by mobile/.build-trigger — set
# "Files Changed" to that file in the Xcode Cloud workflow Start Conditions.
#
# Steps:
#   1. Source Homebrew environment (correct Ruby/pod load path)
#   2. Write GoogleService-Info.plist from secret env var
#   3. Install Flutter (stable) — not pre-installed on Xcode Cloud agents
#   4. flutter pub get — fetches Dart packages, generates Generated.xcconfig
#   5. pod install — fetches iOS CocoaPods using Homebrew's Ruby
#
# Secrets required in Xcode Cloud workflow environment variables:
#   GOOGLE_SERVICE_INFO_PLIST  — base64-encoded GoogleService-Info.plist
#   To generate: base64 -i GoogleService-Info.plist | pbcopy
#
# Requirements:
#   - git mode must be 100755 (executable)
#   - shebang must be #!/bin/zsh (default shell on Xcode Cloud macOS agents)

set -e

echo "================================================"
echo " PayKey iOS — Xcode Cloud post-clone setup"
echo "================================================"

# ── Resolve paths ─────────────────────────────────────────────────────────────
# Strip any trailing slash from CI_PRIMARY_REPOSITORY_PATH
REPO_ROOT="${CI_PRIMARY_REPOSITORY_PATH%/}"
if [ -z "$REPO_ROOT" ]; then
  REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
fi
MOBILE_DIR="$REPO_ROOT/mobile"
FLUTTER_DIR="$HOME/flutter"
FLUTTER_DIR_TMP="$HOME/flutter_tmp"

echo "Repo root : $REPO_ROOT"
echo "Mobile dir: $MOBILE_DIR"
echo "Flutter   : $FLUTTER_DIR"

# ── 1. Homebrew environment ───────────────────────────────────────────────────
# Source Homebrew's environment so pod, ruby, and gem all resolve to the
# Homebrew-managed versions — not the write-protected system Ruby.
# Handles both Apple Silicon (/opt/homebrew) and Intel (/usr/local) agents.
echo ""
echo "🍺 Sourcing Homebrew environment..."
if [ -x "/opt/homebrew/bin/brew" ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x "/usr/local/bin/brew" ]; then
  eval "$(/usr/local/bin/brew shellenv)"
else
  echo "⚠️  Homebrew not found — pod may fail if system Ruby is used"
fi

echo "Ruby : $(ruby --version 2>/dev/null || echo 'not found')"
echo "Pod  : $(pod --version 2>/dev/null || echo 'not found')"

# ── 2. Write GoogleService-Info.plist ─────────────────────────────────────────
# Gitignored for security — must be provided as a base64 env var secret.
# In Xcode Cloud: Workflow → Environment → Environment Variables →
#   Name: GOOGLE_SERVICE_INFO_PLIST  Secret: true
#   Value: output of: base64 -i GoogleService-Info.plist
echo ""
PLIST_DEST="$REPO_ROOT/mobile/ios/Runner/GoogleService-Info.plist"
if [ -n "$GOOGLE_SERVICE_INFO_PLIST" ]; then
  echo "🔑 Writing GoogleService-Info.plist from secret..."
  echo "$GOOGLE_SERVICE_INFO_PLIST" | base64 --decode > "$PLIST_DEST"
  echo "✅ GoogleService-Info.plist written"
elif [ -f "$PLIST_DEST" ]; then
  echo "✅ GoogleService-Info.plist already present (local build)"
else
  echo "❌ ERROR: GOOGLE_SERVICE_INFO_PLIST secret is not set and the file is missing."
  echo "   Add it in Xcode Cloud: Workflow → Environment → Environment Variables"
  exit 1
fi

# ── 3. Install Flutter (stable) ───────────────────────────────────────────────
# Clone to a temp location first — if the clone fails partway the temp dir
# is removed, so the next run doesn't skip the clone and fail on a partial SDK.
echo ""
if [ ! -f "$FLUTTER_DIR/bin/flutter" ]; then
  echo "📦 Cloning Flutter (stable)..."
  # Remove any partial clone from a previous failed attempt
  rm -rf "$FLUTTER_DIR" "$FLUTTER_DIR_TMP"
  git clone https://github.com/flutter/flutter.git \
    --branch stable \
    --depth 1 \
    "$FLUTTER_DIR_TMP"
  mv "$FLUTTER_DIR_TMP" "$FLUTTER_DIR"
  echo "✅ Flutter cloned successfully"
else
  echo "✅ Flutter already present at $FLUTTER_DIR"
fi

export PATH="$FLUTTER_DIR/bin:$PATH"

# Precache dart to avoid a download during flutter --version
flutter precache --ios 2>/dev/null || true
flutter config --no-analytics 2>/dev/null || true

echo ""
echo "🔍 Flutter : $(cat "$FLUTTER_DIR/version" 2>/dev/null || flutter --version --machine 2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin).get('frameworkVersion','unknown'))" 2>/dev/null || echo 'unknown')"

# ── 3. flutter pub get ────────────────────────────────────────────────────────
echo ""
echo "📦 Running flutter pub get..."
cd "$MOBILE_DIR"
flutter pub get

# ── 4. pod install ────────────────────────────────────────────────────────────
# Skip --repo-update if the specs repo is already present (saves ~60s).
# The agent's Homebrew pod ships with a recent specs cache.
echo ""
echo "📦 Running pod install..."
cd "$MOBILE_DIR/ios"

SPECS_DIR="$HOME/.cocoapods/repos/trunk"
if [ -d "$SPECS_DIR" ]; then
  echo "   (specs repo present — skipping --repo-update)"
  pod install
else
  echo "   (no specs repo — running with --repo-update)"
  pod install --repo-update
fi

echo ""
echo "================================================"
echo " ✅ post-clone setup complete"
echo "================================================"
