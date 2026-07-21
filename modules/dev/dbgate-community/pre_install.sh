#!/usr/bin/env bash
set -euo pipefail

source "${LIB_DIR}/installer_external.sh"
source "${LIB_DIR}/state.sh"

url="https://github.com/dbgate/dbgate/releases/latest/download/dbgate-latest.deb"

log_info "[$CANONICAL_ID] Creating temporary download file"

if ! download_file_path="$(mktemp --suffix=.deb)"; then
    log_error "[$CANONICAL_ID] Failed to create temporary file"

    exit 1
fi

log_info "[$CANONICAL_ID] Downloading latest DbGate Community package"

if ! download_file \
    "$CANONICAL_ID" \
    "$url" \
    "$download_file_path"
then
    log_error "[$CANONICAL_ID] Download failed"
    rm -f "$download_file_path"

    exit 2
fi

set_state "DEB_FILE" "$download_file_path"

if ! save_states "$CANONICAL_ID"; then
    log_error "[$CANONICAL_ID] Failed to save installation state"
    rm -f "$download_file_path"

    exit 3
fi

log_info "[$CANONICAL_ID] Download completed successfully"
