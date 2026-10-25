#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/install-target.sh"
source "$LIB_WORKFLOW/latest-version.sh"
source "$LIB_WORKFLOW/stateful-downloader.sh"

__download_artifacts() {
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

__cleanup_artifacts() {
    local key
    local file

    for key in "BINARY_FILE" "THEMES_FILE"; do
        if file="$(get_state "$key")"; then
            rm -f -- "$file"
        fi
    done
}

install_dir="${OH_MY_POSH_INSTALL_DIR:-$INSTALL_DIR/oh-my-posh}"

valid_install_target "$CANONICAL_ID" "$install_dir" "OH_MY_POSH_INSTALL_DIR" || exit $?
__download_artifacts "$CANONICAL_ID" || {
    __cleanup_artifacts

    return 1
}
