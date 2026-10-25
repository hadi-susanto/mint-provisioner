#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/misc/junie/resolver.sh"

declare -A release=()

platform="$(resolve_junie_platform "$CANONICAL_ID")" || exit $?
resolve_junie_release "$CANONICAL_ID" "$platform" release || exit $?
printf '%s\n' "${release[VERSION]}"
