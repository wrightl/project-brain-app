#!/usr/bin/env bash
# Apply geolocator_apple BYPASS_PERMISSION_LOCATION_ALWAYS for Swift Package Manager builds.
# Flutter links geolocator via FlutterGeneratedPluginSwiftPackage (SPM), not CocoaPods.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
shopt -s nullglob

found=0
for pkg in "${ROOT}"/ios/Flutter/ephemeral/Packages/.packages/geolocator_apple-*/Package.swift; do
  found=1
  if grep -q 'BYPASS_PERMISSION_LOCATION_ALWAYS' "$pkg"; then
    echo "geolocator_apple SPM bypass already present"
    continue
  fi

  python3 - "$pkg" <<'PY'
import sys

path = sys.argv[1]
text = open(path, encoding="utf-8").read()
needle = '.headerSearchPath("include/geolocator_apple")'
replacement = (
    needle
    + ',\n                .define("BYPASS_PERMISSION_LOCATION_ALWAYS", to: "1")'
)
if needle not in text:
    raise SystemExit(f"unexpected geolocator_apple Package.swift format: {path}")
open(path, "w", encoding="utf-8").write(text.replace(needle, replacement, 1))
print(f"Applied geolocator_apple SPM bypass: {path}")
PY
done

if [[ "$found" -eq 0 ]]; then
  echo "warning: geolocator_apple Package.swift not found — run flutter pub get first" >&2
fi
