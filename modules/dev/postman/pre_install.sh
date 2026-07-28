#!/usr/bin/env bash
set -euo pipefail

source "${LIB_DIR}/installer_external.sh"
source "${LIB_DIR}/state.sh"

download_url="https://dl.pstmn.io/download/latest/linux64"

log_info "[$CANONICAL_ID] Creating temporary download file"

if ! archive_file="$(mktemp --suffix=.tar.gz)"; then
    log_error "[$CANONICAL_ID] Failed to create temporary file"

    exit 1
fi

log_info "[$CANONICAL_ID] Downloading the latest Postman Linux archive"

if ! download_file "$CANONICAL_ID" "$download_url" "$archive_file"; then
    log_error "[$CANONICAL_ID] Download failed"
    rm -f "$archive_file"

    exit 2
fi

if ! set_state "ARCHIVE_FILE" "$archive_file"; then
    log_error "[$CANONICAL_ID] Failed to store installation state"
    rm -f "$archive_file"

    exit 3
fi

if ! save_states "$CANONICAL_ID"; then
    log_error "[$CANONICAL_ID] Failed to save installation state"
    rm -f "$archive_file"

    exit 4
fi

log_info "[$CANONICAL_ID] Download completed successfully"
