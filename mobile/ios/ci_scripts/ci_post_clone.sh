#!/bin/zsh

# ci_post_clone.sh — Xcode Cloud post-clone script for PayKey (Flutter/iOS)
#
# Xcode Cloud does NOT ship with Flutter. This script:
#   1. Installs Flutter via git clone (stable channel)
#   2. Runs flutter pub get to fetch Dart dependencies
#   3. Installs CocoaPods via gem (avoids Homebrew pod version conflicts)
#   4. Runs pod install to fetch iOS CocoaPods dependencies
#
# Requirements:
#   - File must be executable (mode 100755 in git)
#   - Shebang must be #!/bin/zsh (default shell on Xcode Cloud macOS agents)

set -e  # Exit immediately on any error

echo "================================================"
echo " PayKey iOS — Xcode Cloud post-clone setup"
echo "================================================"

# ── 1. Resolve paths ──────────────────────────────────────────────────────────
# CI_PRIMARY_REPOSITORY_PATH is set by Xcode Cloud to the repo root.
# Fall back to deriving from this script's location if running locally.
REPO_ROOT="${CI_PRIMARY_REPOSITORY_PATH:-$(cd "$(dirname "$0")/../../.." && pwd)}"
MOBILE_DIR="$REPO_ROOT/mobile"
FLUTTER_DIR="$HOME/flutter"

echo "Repo root : $REPO_ROOT"
echo "Mobile dir: $MOBILE_DIR"
echo "Flutter   : $FLUTTER_DIR"

# ── 2. Install Flutter (stable) ───────────────────────────────────────────────
if [ ! -d "$FLUTTER_DIR" ]; then
  echo ""
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

# Disable analytics / crash reporting in CI
flutter config --no-analytics 2>/dev/null || true

# ── 3. flutter pub get ────────────────────────────────────────────────────────
echo ""
echo "📦 Running flutter pub get..."
cd "$MOBILE_DIR"
flutter pub get

# ── 4. Install CocoaPods via gem ──────────────────────────────────────────────
# Xcode Cloud ships with CocoaPods via Homebrew, but the Homebrew-installed
# version can conflict with the system Ruby used by the Podfile.
# Installing via gem ensures compatibility and avoids the load path errors.
echo ""
echo "📦 Installing CocoaPods gem..."
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
