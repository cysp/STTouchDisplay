#!/usr/bin/env bash
set -euo pipefail

if (( $# > 1 )); then
  printf 'Usage: %s [Xcode destination]\n' "$0" >&2
  exit 2
fi

default_destination='platform=iOS Simulator,name=iPhone 17,OS=latest'
destination=${1:-$default_destination}

exec "$(dirname "$0")/lib/xcodebuild.sh" test \
  -project STTouchDisplay.xcodeproj \
  -scheme STTouchDisplay \
  -configuration Debug \
  -destination "$destination" \
  -parallel-testing-enabled NO
