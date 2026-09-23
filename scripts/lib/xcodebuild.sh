#!/usr/bin/env bash
set -euo pipefail

action=${1:?expected xcodebuild action}
shift

repo_root=$(cd "$(dirname "$0")/../.." && pwd)
cd "$repo_root"

exec xcodebuild -quiet \
  "$@" \
  -derivedDataPath "$repo_root/DerivedData" \
  CODE_SIGNING_ALLOWED=NO \
  GCC_TREAT_WARNINGS_AS_ERRORS=YES \
  "$action"
