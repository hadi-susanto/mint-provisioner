#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/downloader.sh"
source "$LIB_INSTALLER/state.sh"
source "$LIB_WORKFLOW/install-target.sh"
source "$LIB_WORKFLOW/misc/junie/resolver.sh"
source "$LIB_WORKFLOW/stateful-downloader.sh"

main() {
    local canonical_id="$1"
    local raw_install_path="$2"
    local platform
    local -A release=()

    valid_install_target "$canonical_id" "$raw_install_path" "JUNIE_INSTALL_DIR" || return $?

    platform="$(resolve_junie_platform "$canonical_id")" || return $?
    tlog_info "pre-install:$canonical_id" "Resolving latest Junie release for %s" "$platform"
    resolve_junie_release "$canonical_id" "$platform" release || return $?

    tlog_info "pre-install:$canonical_id" "Downloading Junie %s (%s)" \
        "${release[VERSION]}" "$platform"
    stateful_download "$canonical_id" "ARCHIVE_FILE" "${release[URL]}" ".zip" 1 \
        "${release[CHECKSUM]}" "${release[VERSION]}"
}

main "$CANONICAL_ID" "${JUNIE_INSTALL_DIR:-$INSTALL_DIR/junie}"
