#!/usr/bin/env bash
set -euo pipefail

exec "$(dirname "$0")/lib/xcodebuild.sh" build \
  -project STTouchDisplay.xcodeproj \
  -scheme STTouchDisplay \
  -configuration Release \
  -destination 'generic/platform=iOS Simulator'
