#!/usr/bin/env bash
# Upload an IPA to TestFlight and sync App Store listing metadata via Fastlane.
#
# Usage:
#   ./scripts/upload_ios_appstore.sh <staging|production> --ipa <path> [--metadata]
#   ./scripts/upload_ios_appstore.sh <staging|production> --metadata
#   ./scripts/upload_ios_appstore.sh <staging|production> --download-metadata [--with-screenshots]
#
# Credentials (same as build_ios.sh):
#   scripts/.asc.<env>  ASC_API_KEY_ID and ASC_API_ISSUER_ID
#   private_keys/AuthKey_<ASC_API_KEY_ID>.p8 at the project root
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=lib/asc_credentials.sh
source "${ROOT}/scripts/lib/asc_credentials.sh"

usage() {
  cat <<'EOF'
Usage: ./scripts/upload_ios_appstore.sh <staging|production> [options]

Options:
  --ipa <path>          Path to the IPA to upload to TestFlight
  --metadata            Upload App Store listing metadata and screenshots (no binary)
  --download-metadata   Pull listing text from App Store Connect into ios/fastlane/metadata/
  --with-screenshots    Also pull screenshots (only with --download-metadata)
  -h, --help            Show this help

At least one of --ipa, --metadata, or --download-metadata is required.
--metadata and --download-metadata cannot be used together.

Examples:
  ./scripts/upload_ios_appstore.sh staging --ipa build/ios/ipa/Runner.ipa
  ./scripts/upload_ios_appstore.sh production --ipa build/ios/ipa/Runner.ipa --metadata
  ./scripts/upload_ios_appstore.sh production --metadata
  ./scripts/upload_ios_appstore.sh production --download-metadata
  ./scripts/upload_ios_appstore.sh production --download-metadata --with-screenshots

Prerequisites:
  cd ios && bundle install   # once per machine / CI image
EOF
}

normalize_environment() {
  case "$1" in
    staging) echo "staging" ;;
    production | prod) echo "production" ;;
    *) return 1 ;;
  esac
}

ENVIRONMENT=""
IPA_PATH=""
UPLOAD_METADATA=false
DOWNLOAD_METADATA=false
WITH_SCREENSHOTS=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h | --help)
      usage
      exit 0
      ;;
    --ipa)
      [[ $# -ge 2 ]] || asc_die "--ipa requires a path"
      IPA_PATH="$2"
      shift 2
      ;;
    --metadata)
      UPLOAD_METADATA=true
      shift
      ;;
    --download-metadata)
      DOWNLOAD_METADATA=true
      shift
      ;;
    --with-screenshots)
      WITH_SCREENSHOTS=true
      shift
      ;;
    -*)
      asc_die "unknown option: $1 (run with --help)"
      ;;
    *)
      if [[ -n "$ENVIRONMENT" ]]; then
        asc_die "unexpected argument: $1 (only one ENVIRONMENT is allowed)"
      fi
      ENVIRONMENT="$1"
      shift
      ;;
  esac
done

[[ -n "$ENVIRONMENT" ]] || { usage >&2; asc_die "ENVIRONMENT is required (staging or production)"; }

NORMALIZED_ENV="$(normalize_environment "$ENVIRONMENT")" || asc_die "invalid ENVIRONMENT: $ENVIRONMENT (use staging or production)"

[[ -n "$IPA_PATH" || "$UPLOAD_METADATA" == "true" || "$DOWNLOAD_METADATA" == "true" ]] \
  || asc_die "at least one of --ipa, --metadata, or --download-metadata is required"

[[ "$UPLOAD_METADATA" == "false" || "$DOWNLOAD_METADATA" == "false" ]] \
  || asc_die "--metadata and --download-metadata cannot be used together"

[[ "$WITH_SCREENSHOTS" == "false" || "$DOWNLOAD_METADATA" == "true" ]] \
  || asc_die "--with-screenshots requires --download-metadata"

[[ "$(uname -s)" == "Darwin" ]] || asc_die "iOS uploads require macOS"

validate_asc_private_key
ensure_fastlane_bundler

if [[ -n "$IPA_PATH" ]]; then
  [[ -f "$IPA_PATH" ]] || asc_die "IPA not found: ${IPA_PATH}"
  if [[ "$IPA_PATH" != /* ]]; then
    IPA_PATH="${ROOT}/${IPA_PATH}"
  fi
fi

cd "${ROOT}/ios"

if [[ -n "$IPA_PATH" ]]; then
  echo "Uploading IPA to TestFlight via Fastlane..."
  echo "cmd: bundle exec fastlane upload_ipa ipa:${IPA_PATH}"
  bundle exec fastlane upload_ipa "ipa:${IPA_PATH}"
  echo "IPA upload complete. TestFlight processing may take several minutes."
fi

if [[ "$UPLOAD_METADATA" == "true" ]]; then
  echo "Uploading App Store metadata via Fastlane deliver..."
  echo "cmd: bundle exec fastlane upload_metadata"
  bundle exec fastlane upload_metadata
  echo "Metadata upload complete."
fi

if [[ "$DOWNLOAD_METADATA" == "true" ]]; then
  echo "Downloading App Store metadata from App Store Connect..."
  if [[ "$WITH_SCREENSHOTS" == "true" ]]; then
    echo "cmd: bundle exec fastlane download_metadata screenshots:true"
    bundle exec fastlane download_metadata screenshots:true
  else
    echo "cmd: bundle exec fastlane download_metadata"
    bundle exec fastlane download_metadata
  fi
  echo "Metadata download complete -> ios/fastlane/metadata/"
  if [[ "$WITH_SCREENSHOTS" == "true" ]]; then
    echo "Screenshots download complete -> ios/fastlane/screenshots/"
  fi
fi

echo "App Store Connect: https://appstoreconnect.apple.com"
