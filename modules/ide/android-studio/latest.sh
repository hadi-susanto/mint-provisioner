#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/ide/android-studio/resolver.sh"

declare -A release_info=()
android_studio_latest_release "$CANONICAL_ID" release_info || exit $?

printf '%s\n' "${release_info[VERSION]}"
