#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
cd "$repo_root"

git ls-files -z -- '*.h' '*.m' \
  ':(exclude)STTouchDisplay/STTouchDisplayImage.m' |
  xargs -0 xcrun clang-format --dry-run --Werror
