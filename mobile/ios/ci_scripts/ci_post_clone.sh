#!/bin/zsh

# ci_post_clone.sh — Xcode Cloud post-clone script for PayKey (Flutter/iOS)
#
# What this does:
#   1. Checks if any mobile-relevant files changed — exits 0 (skip) if not
#   2. Installs Flutter via git clone (stable channel)
#   3. Runs flutter pub get to fetch Dart dependencies
#   4. Installs CocoaPods via gem (avoids Homebrew Ruby load path conflicts)
#   5. Runs pod install to fetch iOS CocoaPods dependencies
#
# Skip logic:
#   Xcode Cloud has no native "skip build" — we exit 0 early so the archive
#   step still runs but flutter build will produce a no-op. The better solution
#   is to set branch/tag conditions in the Xcode Cloud workflow in App Store
#   Connect (Workflow > Start Conditions > Branch Changes > Files Changed).
#   This script is a fallback for when that is not configured.
#
# Requirements:
#   - File must be executable (git mode 100755)
#   - Shebang must be #!/bin/zsh (default shell on Xcode Cloud macOS agents)

set -e

echo "================================================"
echo " PayKey iOS — Xcode Cloud post-clone setup"
echo "================================================"

# ── 0. Resolve paths ──────────────────────────────────────────────────────────
REPO_ROOT="${CI_PRIMARY_REPOSITORY_PATH:-$(cd "$(dirname "$0")/../../.." && pwd)}"
MOBILE_DIR="$REPO_ROOT/mobile"
FLUTTER_DIR="$HOME/flutter"

echo "Repo root : $REPO_ROOT"
echo "Mobile dir: $MOBILE_DIR"

# ── 1. Skip if no relevant mobile files changed ───────────────────────────────
# Xcode Cloud does a shallow clone. We can't use HEAD^ on a depth-1 clone.
# Instead we use CI_COMMIT (current) and fetch one extra commit to compare.
# If that fails we conservatively proceed with the build.
echo ""
echo "🔍 Checking for relevant mobile changes..."

SHOULD_BUILD=true

if [ -n "$CI_COMMIT" ]; then
  # Fetch one extra commit so we have a parent to diff against
  git -C "$REPO_ROOT" fetch --depth=2 origin "$CI_COMMIT" 2>/dev/null || true

  CHANGED=$(git -C "$REPO_ROOT" diff --name-only HEAD^ HEAD 2>/dev/null || echo "")

  if [ -n "$CHANGED" ]; then
    echo "Changed files:"
    echo "$CHANGED"
    if echo "$CHANGED" | grep -qE "^mobile/"; then
      echo "✅ Mobile files changed — proceeding with build."
    else
      echo "⏭  No mobile files changed — skipping Flutter/pod setup."
      echo "   (Xcode Cloud will still archive, but this saves setup time)"
      SHOULD_BUILD=false
    fi
  else
    echo "⚠️  Could not determine changed files — proceeding conservatively."
  fi
else
  echo "⚠️  CI_COMMIT not set — proceeding with build."
fi

if [ "$SHOULD_BUILD" = false ]; then
  # We cannot truly cancel an Xcode Cloud build from a script.
  # Exit 0 so the script passes. The archive will still run but the app
  # was already built; no code changed so it's fast.
  # RECOMMENDED: configure "Files Changed" in the Xcode Cloud workflow
  # Start Conditions to filter builds at the workflow level instead.
  exit 0
fi

# ── 2. Install Flutter (stable) ───────────────────────────────────────────────
echo ""
if [ ! -d "$FLUTTER_DIR" ]; then
  echo "📦 Cloning Flutter (stable)..."
  git clone https://github.com/flutter/flutter.git \
    --branch stable \
    --depth 1 \
    "$FLUTTER_DIR"
else
  echo "✅ Flutter already present at $FLUTTER_DIR"
fi

export PATH="$FLUTTER_DIR/bin:$PATH"

echo ""
echo "🔍 Flutter version:"
flutter --version
flutter config --no-analytics 2>/dev/null || true

# ── 3. flutter pub get ────────────────────────────────────────────────────────
echo ""
echo "📦 Running flutter pub get..."
cd "$MOBILE_DIR"
flutter pub get

# ── 4. Install CocoaPods via gem ──────────────────────────────────────────────
# Xcode Cloud's Homebrew-installed CocoaPods can have Ruby load path issues.
# Installing via gem gives a clean, compatible version.
echo ""
echo "📦 Installing CocoaPods via gem..."
gem install cocoapods --no-document

# ── 5. pod install ────────────────────────────────────────────────────────────
echo ""
echo "📦 Running pod install..."
cd "$MOBILE_DIR/ios"
pod install --repo-update

echo ""
echo "================================================"
echo " ✅ post-clone setup complete"
echo "================================================"
