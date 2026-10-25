#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")/.."
"build/Cyan GitHub.app/Contents/MacOS/Cyan GitHub" --self-test
codesign --verify --deep --strict "build/Cyan GitHub.app"
