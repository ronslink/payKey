#!/bin/sh

# ci_post_clone.sh — Xcode Cloud post-clone script for PayKey (Flutter/iOS)
#
# Xcode Cloud does NOT ship with Flutter. This script:
#   1. Installs Flutter via git clone (stable channel)
#   2. Runs flutter pub get to fetch Dart dependencies
#   3. Runs pod install to fetch iOS CocoaPods dependencies
#
# Xcode Cloud environment notes:
#   - macOS agent, Homebrew is available
#   - The repo is cloned to $CI_PRIMARY_REPOSITORY_PATH (the repo root)
#   - Working directory when this script runs is the repo root
#   - ci_scripts/ must be executable (chmod +x) and start with #!/bin/sh

set -e  # Exit immediately on any error

echo "================================================"
echo " PayKey iOS — Xcode Cloud post-clone setup"
echo "================================================"

# ── 1. Resolve paths ──────────────────────────────────────────────────────────
# Xcode Cloud sets CI_PRIMARY_REPOSITORY_PATH to the repo root.
# Fall back to deriving it from this script's location if not set.
REPO_ROOT="${CI_PRIMARY_REPOSITORY_PATH:-$(cd "$(dirname "$0")/../../.." && pwd)}"
MOBILE_DIR="$REPO_ROOT/mobile"
FLUTTER_DIR="$HOME/flutter"

echo "Repo root : $REPO_ROOT"
echo "Mobile dir: $MOBILE_DIR"
echo "Flutter   : $FLUTTER_DIR"

# ── 2. Install Flutter (stable) ───────────────────────────────────────────────
if [ ! -d "$FLUTTER_DIR" ]; then
  echo ""
  echo "📦 Installing Flutter (stable)..."
  git clone https://github.com/flutter/flutter.git \
    --branch stable \
    --depth 1 \
    "$FLUTTER_DIR"
else
  echo "✅ Flutter already installed at $FLUTTER_DIR"
fi

# Add flutter to PATH for the rest of this script
export PATH="$FLUTTER_DIR/bin:$PATH"

echo ""
echo "🔍 Flutter version:"
flutter --version

# Disable analytics and crash reporting in CI
flutter config --no-analytics 2>/dev/null || true

# ── 3. flutter pub get ────────────────────────────────────────────────────────
echo ""
echo "📦 Running flutter pub get..."
cd "$MOBILE_DIR"
flutter pub get

# ── 4. pod install ────────────────────────────────────────────────────────────
echo ""
echo "📦 Running pod install..."
cd "$MOBILE_DIR/ios"

# Ensure CocoaPods is up to date (Xcode Cloud agents ship with it)
pod install --repo-update

echo ""
echo "================================================"
echo " ✅ post-clone setup complete"
echo "================================================"
