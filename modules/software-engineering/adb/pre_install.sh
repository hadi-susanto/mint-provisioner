#!/usr/bin/env bash

#
# Pre-install phase for ADB.
#

source "$LIB_DIR/installer_external.sh"

MODULE="adb"
STATE_FILE="$STATE_DIR/adb.path"

log_info "[$MODULE] Creating temporary download file"

if ! download_file="$(mktemp --suffix=.zip)"; then
    log_error "[$MODULE] Failed to create temporary file"

    exit 1
fi

URL="https://dl.google.com/android/repository/platform-tools-latest-linux.zip"

log_info "[$MODULE] Creating state file: $STATE_FILE"

if ! printf '%s\n' "$download_file" > "$STATE_FILE"; then
    log_error "[$MODULE] Failed to create state file"
    rm -f "$download_file"

    exit 2
fi

if ! download_file "$MODULE" "$URL" "$download_file"; then
    log_error "[$MODULE] Download failed"
    rm -f "$STATE_FILE"
    rm -f "$download_file"

    exit 3
fi

log_info "[$MODULE] Download completed successfully"
