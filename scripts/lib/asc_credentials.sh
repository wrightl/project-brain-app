#!/usr/bin/env bash
# Shared App Store Connect API credential helpers for iOS upload scripts.
# Source from project scripts after setting ROOT and NORMALIZED_ENV.

asc_die() {
  echo "error: $*" >&2
  exit 1
}

read_asc_config_value() {
  local file="$1"
  local key="$2"
  local line value
  line="$(grep -E "^${key}=" "$file" | tail -n 1 || true)"
  [[ -n "$line" ]] || return 1
  value="${line#${key}=}"
  value="${value%\"}"
  value="${value#\"}"
  value="${value%\'}"
  value="${value#\'}"
  printf '%s' "$value"
}

load_asc_credentials() {
  [[ -n "${ROOT:-}" ]] || asc_die "ROOT must be set before calling load_asc_credentials"
  [[ -n "${NORMALIZED_ENV:-}" ]] || asc_die "NORMALIZED_ENV must be set before calling load_asc_credentials"

  ASC_CONFIG="${ROOT}/scripts/.asc.${NORMALIZED_ENV}"
  ASC_CONFIG_REL="scripts/.asc.${NORMALIZED_ENV}"
  [[ -f "$ASC_CONFIG" ]] || asc_die "missing ${ASC_CONFIG_REL} — copy from scripts/.asc.${NORMALIZED_ENV}.example and fill in values"

  if [[ -z "${ASC_API_KEY_ID:-}" ]]; then
    ASC_API_KEY_ID="$(read_asc_config_value "$ASC_CONFIG" ASC_API_KEY_ID || true)"
    export ASC_API_KEY_ID
  fi

  if [[ -z "${ASC_API_ISSUER_ID:-}" ]]; then
    ASC_API_ISSUER_ID="$(read_asc_config_value "$ASC_CONFIG" ASC_API_ISSUER_ID || true)"
    export ASC_API_ISSUER_ID
  fi

  [[ -n "${ASC_API_KEY_ID:-}" ]] || asc_die "ASC_API_KEY_ID is required for upload (set in ${ASC_CONFIG_REL} or ASC_API_KEY_ID env var)"
  [[ -n "${ASC_API_ISSUER_ID:-}" ]] || asc_die "ASC_API_ISSUER_ID is required for upload (set in ${ASC_CONFIG_REL} or ASC_API_ISSUER_ID env var)"
}

validate_asc_private_key() {
  load_asc_credentials
  KEY_PATH="${ROOT}/private_keys/AuthKey_${ASC_API_KEY_ID}.p8"
  [[ -f "$KEY_PATH" ]] || asc_die "missing App Store Connect private key: ${KEY_PATH}"
}

ensure_fastlane_bundler() {
  [[ -f "${ROOT}/ios/Gemfile" ]] || asc_die "missing ios/Gemfile — run from project root after pulling latest"
  command -v bundle >/dev/null 2>&1 || asc_die "bundler not found — install with: gem install bundler"
  if [[ ! -f "${ROOT}/ios/Gemfile.lock" ]]; then
    asc_die "missing ios/Gemfile.lock — run: cd ios && bundle install"
  fi
}
