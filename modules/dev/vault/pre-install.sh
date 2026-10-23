#!/usr/bin/env bash
set -euo pipefail

source "$LIB_COMMON/common.sh"
source "$LIB_INSTALLER/path.sh"
source "$LIB_WORKFLOW/install-target.sh"
source "$LIB_WORKFLOW/stateful-downloader.sh"

# Prints the latest Vault version published by HashiCorp.
__resolve_version() {
    local canonical_id="$1"
    local tag="pre-install:$canonical_id"
    local response
    local version

    if ! response="$(curl -fsSL "https://checkpoint-api.hashicorp.com/v1/check/vault")"; then
        tlog_error "$tag" "Failed to query the latest Vault version"

        return 1
    fi

    version="$(sed -n 's/.*"current_version" *: *"\([0-9][0-9A-Za-z.+-]*\)".*/\1/p' <<<"$response")"

    if [[ -z "$version" ]]; then
        tlog_error "$tag" "Failed to determine the latest Vault version"

        return 1
    fi

    printf '%s\n' "$version"
}

main() {
    local canonical_id="$1"
    local raw_install_path="$2"
    local raw_data_path="$3"
    local tag="pre-install:$canonical_id"
    local install_path
    local data_path
    local version
    local base_url
    local checksum

    if [[ "$(dpkg --print-architecture)" != "amd64" ]]; then
        tlog_error "$tag" "Vault binary installation supports amd64 only"

        return 1
    fi

    if ! command -v setcap >/dev/null 2>&1; then
        tlog_error "$tag" "setcap is required to let Vault lock memory; install it with: sudo apt install libcap2-bin"

        return 1
    fi

    valid_install_target "$canonical_id" "$raw_install_path" "VAULT_INSTALL_DIR" || return $?

    install_path="$(expand_path "$raw_install_path")" || return $?
    data_path="$(expand_path "$raw_data_path")" || return $?

    # Both paths are written into generated scripts and a JSON file without escaping.
    if [[ ! "$install_path" =~ ^/[A-Za-z0-9._/@+-]+$ ]]; then
        tlog_error "$tag" "Invalid VAULT_INSTALL_DIR (absolute path of letters, digits and . _ / @ + - only): %s" \
            "$install_path"

        return 1
    fi

    if [[ ! "$data_path" =~ ^/[A-Za-z0-9._/@+-]+$ ]]; then
        tlog_error "$tag" "Invalid VAULT_DATA_DIR (absolute path of letters, digits and . _ / @ + - only): %s" \
            "$data_path"

        return 1
    fi

    version="$(__resolve_version "$canonical_id")" || return $?
    tlog_info "$tag" "Latest Vault version: %s" "$version"

    base_url="https://releases.hashicorp.com/vault/${version}"
    checksum="$(fetch_sha256_from_sums "$canonical_id" \
        "$base_url/vault_${version}_SHA256SUMS" "vault_${version}_linux_amd64.zip")" || return $?

    stateful_download "$canonical_id" "ARCHIVE_FILE" \
        "$base_url/vault_${version}_linux_amd64.zip" ".zip" 1 "$checksum"
}

main "$CANONICAL_ID" "${VAULT_INSTALL_DIR:-$INSTALL_DIR/vault}" "${VAULT_DATA_DIR:-${VAULT_INSTALL_DIR:-$INSTALL_DIR/vault}/data}"
