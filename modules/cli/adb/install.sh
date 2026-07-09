#!/usr/bin/env bash

#
# Installs ADB from a previously downloaded .zip archive.
#

source "${LIB_DIR}/installer_common.sh"

MODULE="adb"
STATE_FILE="${STATE_DIR}/adb.path"

log_info "[$MODULE] Looking for state file: ${STATE_FILE}"

if [[ ! -f "$STATE_FILE" ]]; then
    log_error "[$MODULE] State file not found"

    exit 1
fi

read -r ARCHIVE_FILE < "$STATE_FILE"

if [[ ! -f "$ARCHIVE_FILE" ]]; then
    log_error "[$MODULE] Archive file not found: ${ARCHIVE_FILE}"

    exit 2
fi

if [[ -z "${ADB_INSTALL_DIR:-}" ]]; then
    ADB_INSTALL_DIR="$INSTALL_DIR/adb"
fi

log_info "[$MODULE] Extracting content to $ADB_INSTALL_DIR"

SUDO_CMD=""
if ! can_write "$ADB_INSTALL_DIR"; then
    SUDO_CMD="sudo"
fi

if ! $SUDO_CMD mkdir -p "$ADB_INSTALL_DIR"; then
    log_error "[$MODULE] Failed to create install directory: $ADB_INSTALL_DIR"

    exit 3
fi

# Extract.
# Google's zip contains a 'platform-tools' directory.
TEMP_EXTRACT_DIR=$(mktemp -d)
if ! unzip -q "$ARCHIVE_FILE" -d "$TEMP_EXTRACT_DIR"; then
    log_error "[$MODULE] Extraction failed"
    rm -rf "$TEMP_EXTRACT_DIR"

    exit 4
fi

if ! $SUDO_CMD cp -r "${TEMP_EXTRACT_DIR}/platform-tools/." "$ADB_INSTALL_DIR/"; then
    log_error "[$MODULE] Failed to copy extracted files"
    rm -rf "$TEMP_EXTRACT_DIR"

    exit 5
fi

rm -rf "$TEMP_EXTRACT_DIR"

add_to_path "$MODULE" "$ADB_INSTALL_DIR"

log_info "[$MODULE] Installation completed successfully"
