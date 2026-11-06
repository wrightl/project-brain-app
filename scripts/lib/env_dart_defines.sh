#!/usr/bin/env bash
# Read KEY=value assignments from a .env file and append --dart-define flags.
#
# Usage (pass the name of a bash array; Bash 3.2–compatible, no namerefs):
#   BUILD_ARGS=(build ipa)
#   append_dart_defines_from_env BUILD_ARGS ".env.staging"
#
# Skips blank lines, comment lines, empty values, and ENVIRONMENT (set
# separately). A trailing comment needs whitespace before the #; a # inside
# a value is kept.
append_dart_defines_from_env() {
  local out_name=$1
  local env_file=$2

  [[ -f "$env_file" ]] || return 0

  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    [[ -z "$line" || "$line" == \#* ]] && continue
    [[ "$line" != *=* ]] && continue

    local key="${line%%=*}"
    key="${key#"${key%%[![:space:]]*}"}"
    key="${key%"${key##*[![:space:]]}"}"
    [[ "$key" == "ENVIRONMENT" ]] && continue

    local value="${line#*=}"
    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"

    if [[ "$value" =~ ^\"([^\"]*)\" ]]; then
      value="${BASH_REMATCH[1]}"
    elif [[ "$value" =~ ^\'([^\']*)\' ]]; then
      value="${BASH_REMATCH[1]}"
    else
      # Unquoted: only " #" starts a comment, so a # inside a value (keys,
      # URLs with fragments) is kept.
      value="${value%%[[:space:]]#*}"
      value="${value%"${value##*[![:space:]]}"}"
    fi

    [[ -z "$value" ]] && continue
    # Bash 3.2 has no local -n namerefs; append via the array name.
    eval "${out_name}+=(\"--dart-define=\${key}=\${value}\")"
  done <"$env_file"
}
