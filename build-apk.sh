#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GODOT_BIN="${GODOT:-godot4}"
if ! command -v "$GODOT_BIN" >/dev/null 2>&1; then
  GODOT_BIN="${GODOT:-godot}"
fi
if ! command -v "$GODOT_BIN" >/dev/null 2>&1; then
  echo "Godot 4 executable not found. Set GODOT=/path/to/godot." >&2; exit 1
fi
VERSION="$("$GODOT_BIN" --version | head -n1)"
if [[ "$VERSION" != 4.* ]]; then echo "Godot 4 required; found: $VERSION" >&2; exit 1; fi
mkdir -p "$ROOT/build"
"$GODOT_BIN" --headless --editor --path "$ROOT" --import
"$GODOT_BIN" --headless --path "$ROOT" --quit
"$GODOT_BIN" --headless --path "$ROOT" --export-debug Android "$ROOT/build/tak_khat.apk"
if [[ ! -s "$ROOT/build/tak_khat.apk" ]]; then echo "APK export did not produce build/tak_khat.apk" >&2; exit 1; fi
echo "Created $ROOT/build/tak_khat.apk"
