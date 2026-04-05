#!/usr/bin/env bash
# Auth0.swift defines both WebAuthError.other and DPoPError.other. auth0_flutter's
# WebAuthExtensions.swift uses `case .other:` which is ambiguous. Qualify as WebAuthError.other.
# Re-run after: flutter pub get / flutter pub cache repair (if auth0_flutter version changes).

set -euo pipefail
PUB_CACHE="${PUB_CACHE:-$HOME/.pub-cache}"
TARGET="$PUB_CACHE/hosted/pub.dev/auth0_flutter-2.0.0/darwin/Classes/WebAuth/WebAuthExtensions.swift"

if [[ ! -f "$TARGET" ]]; then
  echo "Expected file missing: $TARGET" >&2
  echo "Adjust path if using a different auth0_flutter version." >&2
  exit 1
fi

if grep -q 'case WebAuthError.other:' "$TARGET"; then
  echo "Already patched: $TARGET"
  exit 0
fi

if ! grep -q 'case \.other: code = "OTHER"' "$TARGET"; then
  echo "Unexpected content in $TARGET — not patching." >&2
  exit 1
fi

if [[ "$(uname -s)" == "Darwin" ]]; then
  sed -i '' 's/case \.other: code = "OTHER"/case WebAuthError.other: code = "OTHER"/' "$TARGET"
else
  sed -i 's/case \.other: code = "OTHER"/case WebAuthError.other: code = "OTHER"/' "$TARGET"
fi
echo "Patched: $TARGET"
