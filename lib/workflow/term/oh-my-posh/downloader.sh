#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_OH_MY_POSH_DOWNLOADER_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_OH_MY_POSH_DOWNLOADER_LOADED=1

source "$LIB_INSTALLER/downloader.sh"
source "$LIB_INSTALLER/state.sh"
source "$LIB_WORKFLOW/latest-version.sh"
source "$LIB_WORKFLOW/stateful-downloader.sh"

__download_oh_my_posh_artifacts() {
    local canonical_id="$1"
    local version
    local base_url
    local binary_url
    local themes_url
    local binary_checksum

    version="$(module_latest_version "$canonical_id")" || return $?
    base_url="https://cdn.ohmyposh.dev/releases/${version}"
    binary_url="$base_url/posh-linux-amd64"
    themes_url="$base_url/themes.zip"

    # checksums.txt lists the binary only; themes.zip stays unverified.
    binary_checksum="$(fetch_sha256_from_sums "$canonical_id" \
        "$base_url/checksums.txt" "posh-linux-amd64")" || return $?

    stateful_download "$canonical_id" "BINARY_FILE" "$binary_url" "" 0 "$binary_checksum" || return $?
    stateful_download "$canonical_id" "THEMES_FILE" "$themes_url" ".zip" 0 || return $?
    set_state "VERSION" "$version" || return $?
    save_states "$canonical_id"
}

__cleanup_oh_my_posh_artifacts() {
    local key
    local file

    for key in "BINARY_FILE" "THEMES_FILE"; do
        if file="$(get_state "$key" 2>/dev/null)"; then
            rm -f -- "$file" || true
        fi
    done
}

##
# oh_my_posh_download <canonical_id>
#
# Downloads the latest Oh My Posh binary (checksum verified) and themes archive
# into the BINARY_FILE and THEMES_FILE states with the release VERSION. Partial
# downloads are removed on failure. Used by pre-install and pre-upgrade.
#
# Parameters:
#   canonical_id - Canonical module ID.
#
# Return:
#   1 - A lookup, download, or state update failed.
#
oh_my_posh_download() {
    local canonical_id="$1"

    if __download_oh_my_posh_artifacts "$canonical_id"; then
        return 0
    fi

    __cleanup_oh_my_posh_artifacts

    return 1
}
