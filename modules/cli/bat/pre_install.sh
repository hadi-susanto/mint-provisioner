#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/external.sh"
source "$LIB_INSTALLER/state.sh"

main() {
    local canonical_id="$1"
    local release_regex="$2"
    local tag="pre-install:$canonical_id"
    local deb_file
    local url

    if ! deb_file="$(mktemp --suffix=.deb)"; then
        tlog_error "$tag" "Failed to create a temporary package file"

        return 1
    fi

    tlog_info "$tag" "Resolving the latest bat release"
    if ! url="$(
        github_find_release "$canonical_id" sharkdp bat "$release_regex"
    )"; then
        tlog_error "$tag" "Failed to resolve the latest bat release"
        rm -f -- "$deb_file"

        return 2
    fi

    if ! download_file "$canonical_id" "$url" "$deb_file"; then
        tlog_error "$tag" "Failed to download the bat package"
        rm -f -- "$deb_file"

        return 3
    fi

    if ! set_state "DEB_FILE" "$deb_file" || ! save_states "$canonical_id"; then
        tlog_error "$tag" "Failed to save installation state"
        rm -f -- "$deb_file"

        return 4
    fi

    tlog_info "$tag" "Pre-install phase completed successfully"
}

main "$CANONICAL_ID" "${BAT_REGEX:-bat_.*_amd64[.]deb$}"
