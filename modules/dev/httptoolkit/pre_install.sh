#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/external.sh"
source "$LIB_INSTALLER/state.sh"

main() {
    local canonical_id="$1"
    local release_regex="$2"
    local deb_file
    local tag="pre-install:$canonical_id"
    local url

    if ! deb_file="$(mktemp --suffix=.deb)"; then
        tlog_error "$tag" "Failed to create a temporary package file"

        return 1
    fi

    if ! url="$(
        github_find_release \
            "$canonical_id" httptoolkit httptoolkit-desktop "$release_regex"
    )"; then
        tlog_error "$tag" "Failed to resolve the latest HTTP Toolkit release"
        rm -f -- "$deb_file"

        return 2
    fi

    if ! download_file "$canonical_id" "$url" "$deb_file"; then
        tlog_error "$tag" "Failed to download the HTTP Toolkit package"
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

main "$CANONICAL_ID" "${HTTPTOOLKIT_REGEX:-HttpToolkit-.*-x64[.]deb$}"
