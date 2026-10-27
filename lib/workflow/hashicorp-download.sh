#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_HASHICORP_DOWNLOAD_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_HASHICORP_DOWNLOAD_LOADED=1

source "$LIB_INSTALLER/downloader.sh"
source "$LIB_INSTALLER/state.sh"
source "$LIB_WORKFLOW/latest-version.sh"
source "$LIB_WORKFLOW/stateful-downloader.sh"

##
# hashicorp_download_binary <canonical_id> <product>
#
# Downloads the latest linux_amd64 release zip of a HashiCorp product, verifies
# it against the release SHA256SUMS, and unpacks the product binary into a
# temporary file. Saves ARCHIVE_FILE, BINARY_FILE, and VERSION in the module
# state; cleanup.sh removes both files. Used by consul and vault pre-upgrade.
#
# Parameters:
#   canonical_id - Canonical module ID.
#   product - HashiCorp product and binary name, such as consul.
#
# Return:
#   1 - The architecture is unsupported, or a lookup, download, or unpack failed.
#
hashicorp_download_binary() {
    local canonical_id="$1"
    local product="$2"
    local tag="download:$canonical_id"
    local version
    local base_url
    local checksum
    local archive_file
    local binary_file

    if [[ "$(dpkg --print-architecture)" != "amd64" ]]; then
        tlog_error "$tag" "%s binary installation supports amd64 only" "$product"

        return 1
    fi

    version="$(module_latest_version "$canonical_id")" || return $?
    base_url="https://releases.hashicorp.com/${product}/${version}"
    checksum="$(fetch_sha256_from_sums "$canonical_id" \
        "$base_url/${product}_${version}_SHA256SUMS" "${product}_${version}_linux_amd64.zip")" || return $?

    stateful_download "$canonical_id" "ARCHIVE_FILE" \
        "$base_url/${product}_${version}_linux_amd64.zip" ".zip" 0 "$checksum" "$version" || return $?
    archive_file="$(get_state "ARCHIVE_FILE")" || return $?

    if ! binary_file="$(mktemp)"; then
        tlog_error "$tag" "Failed to create a temporary file"

        return 1
    fi

    if ! unzip -p "$archive_file" "$product" >"$binary_file" || [[ ! -s "$binary_file" ]]; then
        tlog_error "$tag" "Failed to unpack %s from %s" "$product" "$archive_file"
        rm -f -- "$binary_file"

        return 1
    fi

    set_state "BINARY_FILE" "$binary_file" || return $?
    save_states "$canonical_id"
}
