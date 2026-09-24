#!/usr/bin/env bash
set -euo pipefail

exec "$(dirname "$0")/lib/xcodebuild.sh" analyze \
  -project Demo/STTouchDisplayDemo.xcodeproj \
  -scheme STTouchDisplayDemo \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator'
