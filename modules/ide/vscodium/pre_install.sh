#!/usr/bin/env bash
set -euo pipefail

source "${LIB_INSTALLER}/external.sh"
source "${LIB_INSTALLER}/state.sh"

tlog_info "$CANONICAL_ID" "Creating temporary download file"

if ! download_file_path="$(mktemp --suffix=.deb)"; then
    tlog_error "$CANONICAL_ID" "Failed to create temporary file"

    exit 1
fi

if [[ -z "${VSCODIUM_REGEX:-}" ]]; then
    VSCODIUM_REGEX='codium_.*_amd64\.deb$'
fi

tlog_info "$CANONICAL_ID" \
    "Finding GitHub latest release using regex: %s" "$VSCODIUM_REGEX"

if ! url="$(
    github_find_release "$CANONICAL_ID" VSCodium vscodium "$VSCODIUM_REGEX"
)"; then
    tlog_error "$CANONICAL_ID" "No release asset matched regex: %s" "$VSCODIUM_REGEX"
    tlog_error "$CANONICAL_ID" "Please check https://github.com/VSCodium/vscodium/releases"
    tlog_error "$CANONICAL_ID" "Alternatively, set VSCODIUM_REGEX to manually select an asset"
    rm -f "$download_file_path"

    exit 2
fi

if ! download_file "$CANONICAL_ID" "$url" "$download_file_path"; then
    tlog_error "$CANONICAL_ID" "Download failed"
    rm -f "$download_file_path"

    exit 3
fi

set_state "DEB_FILE" "$download_file_path"

if ! save_states "$CANONICAL_ID"; then
    tlog_error "$CANONICAL_ID" "Failed to save installation state"
    rm -f "$download_file_path"

    exit 4
fi

tlog_info "$CANONICAL_ID" "Download completed successfully"
