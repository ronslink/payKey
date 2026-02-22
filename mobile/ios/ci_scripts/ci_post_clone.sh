#!/bin/zsh

# ci_post_clone.sh — Xcode Cloud post-clone script for PayKey (Flutter/iOS)
#
# Build triggering is controlled by mobile/.build-trigger — set
# "Files Changed" to that file in the Xcode Cloud workflow Start Conditions.
#
# Steps:
#   1. Install Flutter (stable) — not pre-installed on Xcode Cloud agents
#   2. flutter pub get — fetches Dart packages, generates Generated.xcconfig
#   3. pod install — fetches iOS CocoaPods via Homebrew's Ruby environment
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

# ── Homebrew environment ──────────────────────────────────────────────────────
# Prepend Homebrew paths so 'pod' uses Homebrew's Ruby, not the write-protected
# system Ruby at /Library/Ruby/Gems/2.6.0.
# On Apple Silicon agents: /opt/homebrew; on Intel agents: /usr/local
if [ -x "/opt/homebrew/bin/brew" ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x "/usr/local/bin/brew" ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

echo ""
echo "Ruby : $(ruby --version)"
echo "Pod  : $(pod --version 2>/dev/null || echo 'not found')"

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

# ── 3. pod install ────────────────────────────────────────────────────────────
echo ""
echo "📦 Running pod install..."
cd "$MOBILE_DIR/ios"
pod install --repo-update

echo ""
echo "================================================"
echo " ✅ post-clone setup complete"
echo "================================================"
