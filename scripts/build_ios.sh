#!/usr/bin/env bash
# Build an iOS IPA for the given ENVIRONMENT, bump the pubspec build number,
# and upload to App Store Connect for staging/production (dev skips upload).
#
# Usage:
#   ./scripts/build_ios.sh <dev|staging|production> [--obfuscate] [--no-bump] [--no-upload] [--commit]
#
# Upload credentials (staging/production only):
#   ASC_API_KEY_ID     App Store Connect API Key ID
#   ASC_API_ISSUER_ID  Issuer ID from App Store Connect
#   private_keys/AuthKey_<ASC_API_KEY_ID>.p8 at the project root
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

usage() {
  cat <<'EOF'
Usage: ./scripts/build_ios.sh <dev|staging|production> [options]

Options:
  --obfuscate   Enable Dart obfuscation and write split-debug-info symbols
  --no-bump     Skip incrementing the pubspec build number
  --no-upload   Build IPA only; do not upload to App Store Connect
  --commit      Git-commit pubspec.yaml after a successful build (when bump ran)
  -h, --help    Show this help

Environment variables (required for staging/production upload):
  ASC_API_KEY_ID     App Store Connect API Key ID
  ASC_API_ISSUER_ID  Issuer ID from App Store Connect

Upload behaviour:
  dev         build only (no upload)
  staging     build + upload to App Store Connect / TestFlight
  production  build + upload to App Store Connect / TestFlight
EOF
}

die() {
  echo "error: $*" >&2
  exit 1
}

has_ios_distribution_identity() {
  security find-identity -v -p codesigning 2>/dev/null \
    | grep -Eq '"(Apple Distribution|iPhone Distribution):'
}

check_ios_distribution_signing() {
  if has_ios_distribution_identity; then
    return 0
  fi

  cat >&2 <<'EOF'
error: no iOS Distribution signing certificate found in the login keychain.

The App Store Connect API key (ASC_API_KEY_*) is only used to upload the IPA after
it is built. Exporting an App Store IPA still requires an Apple Distribution
certificate on this Mac.

Fix (one-time setup in Xcode):
  1. open ios/Runner.xcworkspace
  2. Xcode → Settings → Accounts → sign in with your Apple Developer Apple ID
  3. Select team 3JA363674L → Manage Certificates… → + → Apple Distribution
  4. Runner target → Signing & Capabilities → confirm "Automatically manage signing"
     and team 3JA363674L for the Release configuration
  5. Re-run this script

Verify with:
  security find-identity -v -p codesigning | grep Distribution

If you already archived successfully, you can export from Xcode after fixing certs:
  open build/ios/archive/Runner.xcarchive
EOF
  exit 1
}

normalize_environment() {
  case "$1" in
    dev | development) echo "dev" ;;
    staging) echo "staging" ;;
    production | prod) echo "production" ;;
    *) return 1 ;;
  esac
}

# --- Parse arguments ---
ENVIRONMENT=""
OBFUSCATE=false
NO_BUMP=false
NO_UPLOAD=false
DO_COMMIT=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h | --help)
      usage
      exit 0
      ;;
    --obfuscate)
      OBFUSCATE=true
      shift
      ;;
    --no-bump)
      NO_BUMP=true
      shift
      ;;
    --no-upload)
      NO_UPLOAD=true
      shift
      ;;
    --commit)
      DO_COMMIT=true
      shift
      ;;
    -*)
      die "unknown option: $1 (run with --help)"
      ;;
    *)
      if [[ -n "$ENVIRONMENT" ]]; then
        die "unexpected argument: $1 (only one ENVIRONMENT is allowed)"
      fi
      ENVIRONMENT="$1"
      shift
      ;;
  esac
done

[[ -n "$ENVIRONMENT" ]] || { usage >&2; die "ENVIRONMENT is required"; }

NORMALIZED_ENV="$(normalize_environment "$ENVIRONMENT")" || die "invalid ENVIRONMENT: $ENVIRONMENT (use dev, staging, or production)"

# --- Pre-flight checks ---
[[ "$(uname -s)" == "Darwin" ]] || die "iOS IPA builds require macOS"
command -v flutter >/dev/null 2>&1 || die "flutter not found on PATH"
check_ios_distribution_signing

ENV_FILE=".env.${NORMALIZED_ENV}"
[[ -f "$ENV_FILE" ]] || die "missing ${ENV_FILE} — copy from .env.${NORMALIZED_ENV}.example and fill in values"

"${ROOT}/scripts/sync_ios_secrets.sh" "${NORMALIZED_ENV}"

SHOULD_UPLOAD=false
if [[ "$NORMALIZED_ENV" != "dev" && "$NO_UPLOAD" == "false" ]]; then
  SHOULD_UPLOAD=true
fi

if [[ "$SHOULD_UPLOAD" == "true" ]]; then
  [[ -n "${ASC_API_KEY_ID:-}" ]] || die "ASC_API_KEY_ID is required for upload"
  [[ -n "${ASC_API_ISSUER_ID:-}" ]] || die "ASC_API_ISSUER_ID is required for upload"
  KEY_PATH="${ROOT}/private_keys/AuthKey_${ASC_API_KEY_ID}.p8"
  [[ -f "$KEY_PATH" ]] || die "missing App Store Connect private key: ${KEY_PATH}"
fi

if [[ "$NORMALIZED_ENV" != "dev" ]]; then
  ENTITLEMENTS="${ROOT}/ios/Runner/Runner.entitlements"
  if [[ -f "$ENTITLEMENTS" ]] && grep -q '<string>development</string>' "$ENTITLEMENTS" 2>/dev/null; then
    if grep -A1 'aps-environment' "$ENTITLEMENTS" | grep -q 'development'; then
      echo "warning: ios/Runner/Runner.entitlements has aps-environment=development."
      echo "         Verify production push entitlements before App Store review (see STORE_SUBMISSION_CHECKLIST.md)."
    fi
  fi
fi

# --- Version bump ---
PUBSPEC="${ROOT}/pubspec.yaml"
VERSION_LINE="$(grep '^version:' "$PUBSPEC")" || die "could not find version: line in pubspec.yaml"

OLD_VERSION="$(echo "$VERSION_LINE" | sed -E 's/^version:[[:space:]]*//')"
VERSION_NAME="$(echo "$OLD_VERSION" | sed -E 's/^([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)$/\1/')"
BUILD_NUMBER="$(echo "$OLD_VERSION" | sed -E 's/^[0-9]+\.[0-9]+\.[0-9]+\+([0-9]+)$/\1/')"

[[ "$VERSION_NAME" != "$OLD_VERSION" && -n "$BUILD_NUMBER" ]] || die "pubspec version must be x.y.z+build (found: ${OLD_VERSION})"

BUMPED=false
NEW_VERSION="$OLD_VERSION"
if [[ "$NO_BUMP" == "false" ]]; then
  NEW_BUILD=$((BUILD_NUMBER + 1))
  NEW_VERSION="${VERSION_NAME}+${NEW_BUILD}"
  sed -i '' "s/^version: .*/version: ${NEW_VERSION}/" "$PUBSPEC"
  BUMPED=true
  echo "Version: ${OLD_VERSION} -> ${NEW_VERSION}"
else
  echo "Version: ${OLD_VERSION} (unchanged, --no-bump)"
fi

# --- Build ---
echo "Building IPA for environment: ${NORMALIZED_ENV}"
flutter pub get

BUILD_ARGS=(
  build ipa
  "--dart-define=ENVIRONMENT=${NORMALIZED_ENV}"
)

if [[ "$OBFUSCATE" == "true" ]]; then
  SYM_DIR="${ROOT}/build/symbols/ios-${NORMALIZED_ENV}-$(date +%Y%m%d-%H%M%S)"
  mkdir -p "$SYM_DIR"
  BUILD_ARGS+=(--obfuscate "--split-debug-info=${SYM_DIR}")
  echo "Obfuscation symbols -> ${SYM_DIR}"
fi

flutter "${BUILD_ARGS[@]}"

IPA_MATCH=(build/ios/ipa/*.ipa)
if [[ ! -e "${IPA_MATCH[0]}" ]]; then
  die "no IPA found at build/ios/ipa/*.ipa"
fi
if [[ ${#IPA_MATCH[@]} -gt 1 ]]; then
  die "multiple IPAs found in build/ios/ipa/ — clean build/ios and retry"
fi
IPA_PATH="${IPA_MATCH[0]}"
echo "IPA: ${IPA_PATH}"

# --- Upload ---
if [[ "$SHOULD_UPLOAD" == "true" ]]; then
  echo "Uploading to App Store Connect..."
  xcrun altool --upload-app --type ios \
    -f "${IPA_PATH}" \
    --apiKey "${ASC_API_KEY_ID}" \
    --apiIssuer "${ASC_API_ISSUER_ID}"
  echo "Upload complete. Finish TestFlight / App Store steps in App Store Connect:"
  echo "  https://appstoreconnect.apple.com"
else
  echo "Skipping upload (environment=${NORMALIZED_ENV}$([[ "$NO_UPLOAD" == "true" ]] && echo ', --no-upload' || echo ''))."
fi

# --- Optional commit ---
if [[ "$DO_COMMIT" == "true" && "$BUMPED" == "true" ]]; then
  git add pubspec.yaml
  git commit -m "chore(ios): bump build to ${NEW_VERSION} [${NORMALIZED_ENV}]"
  echo "Committed pubspec.yaml version bump."
elif [[ "$DO_COMMIT" == "true" && "$BUMPED" == "false" ]]; then
  echo "Skipping commit (--no-bump was set; nothing to commit)."
fi

echo "Done."
