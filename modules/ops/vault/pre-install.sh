#!/usr/bin/env bash
set -euo pipefail

source "$LIB_COMMON/common.sh"
source "$LIB_INSTALLER/path.sh"
source "$LIB_WORKFLOW/install-target.sh"
source "$LIB_WORKFLOW/latest-version.sh"
source "$LIB_WORKFLOW/stateful-downloader.sh"

tag="pre-install:$CANONICAL_ID"
raw_install_path="${VAULT_INSTALL_DIR:-$INSTALL_DIR/vault}"
raw_data_path="${VAULT_DATA_DIR:-$raw_install_path/data}"

if [[ "$(dpkg --print-architecture)" != "amd64" ]]; then
    tlog_error "$tag" "Vault binary installation supports amd64 only"

    exit 1
fi

if ! command -v setcap >/dev/null 2>&1; then
    tlog_error "$tag" "setcap is required to let Vault lock memory; install it with: sudo apt install libcap2-bin"

    exit 1
fi

valid_install_target "$CANONICAL_ID" "$raw_install_path" "VAULT_INSTALL_DIR" || exit $?

install_path="$(expand_path "$raw_install_path")" || exit $?
data_path="$(expand_path "$raw_data_path")" || exit $?

# Both paths are written into generated scripts and a JSON file without escaping.
if [[ ! "$install_path" =~ ^/[A-Za-z0-9._/@+-]+$ ]]; then
    tlog_error "$tag" "Invalid VAULT_INSTALL_DIR (absolute path of letters, digits and . _ / @ + - only): %s" \
        "$install_path"

    exit 1
fi

if [[ ! "$data_path" =~ ^/[A-Za-z0-9._/@+-]+$ ]]; then
    tlog_error "$tag" "Invalid VAULT_DATA_DIR (absolute path of letters, digits and . _ / @ + - only): %s" \
        "$data_path"

    exit 1
fi

version="$(module_latest_version "$CANONICAL_ID")" || exit $?
tlog_info "$tag" "Latest Vault version: %s" "$version"

base_url="https://releases.hashicorp.com/vault/${version}"
checksum="$(fetch_sha256_from_sums "$CANONICAL_ID" \
    "$base_url/vault_${version}_SHA256SUMS" "vault_${version}_linux_amd64.zip")" || exit $?

stateful_download "$CANONICAL_ID" "ARCHIVE_FILE" \
    "$base_url/vault_${version}_linux_amd64.zip" ".zip" 1 "$checksum" "$version"
