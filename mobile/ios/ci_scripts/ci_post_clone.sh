#!/bin/zsh

# ci_post_clone.sh — Xcode Cloud post-clone script for PayKey (Flutter/iOS)
#
# This script runs after the repo is cloned on the Xcode Cloud agent.
# Build triggering is handled at the workflow level via the sentinel file
# mobile/.build-trigger (set "Files Changed" to that file in App Store Connect:
#   Workflow → Start Conditions → Branch Changes → Files Changed).
#
# Steps:
#   1. Install Flutter (stable) — Xcode Cloud agents do not ship with Flutter
#   2. flutter pub get — fetches Dart packages, generates Flutter/Generated.xcconfig
#   3. gem install cocoapods — avoids Homebrew Ruby load-path conflicts
#   4. pod install — fetches iOS CocoaPods using Flutter's pod helpers
#
# Requirements:
#   - git mode must be 100755 (executable)
#   - shebang must be #!/bin/zsh (default shell on Xcode Cloud macOS agents)

set -e

echo "================================================"
echo " PayKey iOS — Xcode Cloud post-clone setup"
echo "================================================"

# ── Resolve paths ─────────────────────────────────────────────────────────────
REPO_ROOT="${CI_PRIMARY_REPOSITORY_PATH:-$(cd "$(dirname "$0")/../../.." && pwd)}"
MOBILE_DIR="$REPO_ROOT/mobile"
FLUTTER_DIR="$HOME/flutter"

echo "Repo root : $REPO_ROOT"
echo "Mobile dir: $MOBILE_DIR"
echo "Flutter   : $FLUTTER_DIR"

# ── 1. Install Flutter (stable) ───────────────────────────────────────────────
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

# ── 2. flutter pub get ────────────────────────────────────────────────────────
echo ""
echo "📦 Running flutter pub get..."
cd "$MOBILE_DIR"
flutter pub get

# ── 3. Install CocoaPods via gem ──────────────────────────────────────────────
# Xcode Cloud's Homebrew-installed pod runs against a different Ruby load path
# than the system Ruby the Podfile uses — installing via gem avoids this.
echo ""
echo "📦 Installing CocoaPods via gem..."
gem install cocoapods --no-document

# ── 4. pod install ────────────────────────────────────────────────────────────
echo ""
echo "📦 Running pod install..."
cd "$MOBILE_DIR/ios"
pod install --repo-update

echo ""
echo "================================================"
echo " ✅ post-clone setup complete"
echo "================================================"
