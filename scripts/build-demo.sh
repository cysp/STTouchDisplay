#!/usr/bin/env bash
set -euo pipefail

exec "$(dirname "$0")/lib/xcodebuild.sh" build \
  -project Demo/STTouchDisplayDemo.xcodeproj \
  -scheme STTouchDisplayDemo \
  -configuration Release \
  -destination 'generic/platform=iOS Simulator'
