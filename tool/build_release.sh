#!/usr/bin/env bash
# Release artifacts with Dart obfuscation. Upload split-debug-info outputs to
# Firebase Crashlytics (or your symbol server) for readable stack traces.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SYM="${SYM:-$ROOT/build/symbols/$(date +%Y%m%d-%H%M%S)}"
mkdir -p "$SYM"
cd "$ROOT"

echo "Symbols -> $SYM"
flutter build appbundle --release --obfuscate --split-debug-info="$SYM/android"
# iOS: open Xcode to archive, or add codesigning flags as needed.
flutter build ios --release --obfuscate --split-debug-info="$SYM/ios" --no-codesign
