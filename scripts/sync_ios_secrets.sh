#!/usr/bin/env bash
# Sync Google Maps API key from .env.<env> into native iOS and Android config.
#
# Usage:
#   ./scripts/sync_ios_secrets.sh [dev|staging|production]
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

normalize_environment() {
  case "$1" in
    dev | development) echo "dev" ;;
    staging) echo "staging" ;;
    production | prod) echo "production" ;;
    *) return 1 ;;
  esac
}

ENVIRONMENT="${1:-dev}"
NORMALIZED_ENV="$(normalize_environment "$ENVIRONMENT")" || {
  echo "error: invalid environment: ${ENVIRONMENT} (use dev, staging, or production)" >&2
  exit 1
}

ENV_FILE=".env.${NORMALIZED_ENV}"
MAPS_KEY=""

if [[ -f "$ENV_FILE" ]]; then
  line="$(grep -E '^GOOGLE_MAPS_API_KEY=' "$ENV_FILE" | tail -n 1 || true)"
  if [[ -n "$line" ]]; then
    MAPS_KEY="${line#GOOGLE_MAPS_API_KEY=}"
    MAPS_KEY="${MAPS_KEY%\"}"
    MAPS_KEY="${MAPS_KEY#\"}"
    MAPS_KEY="${MAPS_KEY%\'}"
    MAPS_KEY="${MAPS_KEY#\'}"
  fi
fi

if [[ -z "$MAPS_KEY" && -n "${GOOGLE_MAPS_API_KEY:-}" ]]; then
  MAPS_KEY="${GOOGLE_MAPS_API_KEY}"
fi

IOS_OUT="${ROOT}/ios/Flutter/Secrets.xcconfig"
mkdir -p "$(dirname "$IOS_OUT")"
printf 'GOOGLE_MAPS_API_KEY=%s\n' "$MAPS_KEY" >"$IOS_OUT"

ANDROID_LOCAL_PROPS="${ROOT}/android/local.properties"
if [[ -f "$ANDROID_LOCAL_PROPS" ]]; then
  grep -v '^googleMapsApiKey=' "$ANDROID_LOCAL_PROPS" >"${ANDROID_LOCAL_PROPS}.tmp" || true
  mv "${ANDROID_LOCAL_PROPS}.tmp" "$ANDROID_LOCAL_PROPS"
fi
if [[ -n "$MAPS_KEY" ]]; then
  printf 'googleMapsApiKey=%s\n' "$MAPS_KEY" >>"$ANDROID_LOCAL_PROPS"
fi

if [[ -z "$MAPS_KEY" ]]; then
  echo "warning: GOOGLE_MAPS_API_KEY is empty (checked ${ENV_FILE} and env var)."
  echo "         Native map tiles will not load until a key is configured."
else
  echo "Wrote ios/Flutter/Secrets.xcconfig from ${ENV_FILE:-GOOGLE_MAPS_API_KEY env var}."
  echo "Wrote android/local.properties googleMapsApiKey from ${ENV_FILE:-GOOGLE_MAPS_API_KEY env var}."
fi
