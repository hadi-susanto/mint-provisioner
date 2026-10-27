#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/misc/junie/resolver.sh"
source "$LIB_WORKFLOW/stateful-downloader.sh"

declare -A release=()

platform="$(resolve_junie_platform "$CANONICAL_ID")" || exit $?
tlog_info "pre-upgrade:$CANONICAL_ID" "Resolving latest Junie release for %s" "$platform"
resolve_junie_release "$CANONICAL_ID" "$platform" release || exit $?

tlog_info "pre-upgrade:$CANONICAL_ID" "Downloading Junie %s (%s)" "${release[VERSION]}" "$platform"
stateful_download "$CANONICAL_ID" "ARCHIVE_FILE" "${release[URL]}" ".zip" 1 \
    "${release[CHECKSUM]}" "${release[VERSION]}"
