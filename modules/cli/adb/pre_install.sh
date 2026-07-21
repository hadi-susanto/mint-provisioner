#!/usr/bin/env bash
set -euo pipefail

#
# Pre-install phase for ADB.
#

source "$LIB_DIR/installer_external.sh"
source "$LIB_DIR/state.sh"

log_info "[$CANONICAL_ID] Creating temporary download file"

if ! download_file="$(mktemp --suffix=.zip)"; then
    log_error "[$CANONICAL_ID] Failed to create temporary file"

    exit 1
fi

URL="https://dl.google.com/android/repository/platform-tools-latest-linux.zip"

if ! download_file "$CANONICAL_ID" "$URL" "$download_file"; then
    log_error "[$CANONICAL_ID] Download failed"
    rm -f "$download_file"

    exit 2
fi

set_state "ARCHIVE_FILE" "$download_file"
save_states "$CANONICAL_ID" || exit 3

log_info "[$CANONICAL_ID] Download completed successfully"
