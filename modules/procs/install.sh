#!/usr/bin/env bash

source "${LIB_DIR}/installer_common.sh"

MODULE="procs"
STATE_FILE="${STATE_DIR}/procs.path"

if [[ ! -f "$STATE_FILE" ]]; then
    log_error "[$MODULE] State file not found: $STATE_FILE"

    exit 1
fi

read -r ARCHIVE_FILE < "$STATE_FILE"

if [[ ! -f "$ARCHIVE_FILE" ]]; then
    log_error "[$MODULE] Archive file not found: ${ARCHIVE_FILE}"

    exit 2
fi

if [[ -z "${PROCS_INSTALL_DIR:-}" ]]; then
    PROCS_INSTALL_DIR="$INSTALL_DIR/procs"
fi

SUDO_CMD=""
if ! can_write "$(dirname "$PROCS_INSTALL_DIR")"; then
    SUDO_CMD="sudo"
fi

if ! $SUDO_CMD mkdir -p "$PROCS_INSTALL_DIR"; then
    log_error "[$MODULE] Failed to create install directory: $PROCS_INSTALL_DIR"

    exit 3
fi

if ! $SUDO_CMD unzip -oq "$ARCHIVE_FILE" -d "$PROCS_INSTALL_DIR"; then
    log_error "[$MODULE] Extraction failed"

    exit 4
fi

if ! $SUDO_CMD chmod +x "$PROCS_INSTALL_DIR/procs"; then
    log_error "[$MODULE] Failed to make binary executable"

    exit 5
fi

log_info "[$MODULE] Creating symbolic links"
if [[ "$PROCS_INSTALL_DIR" != "$(symlink_location)" ]]; then
    symlink_binary "$MODULE" "$PROCS_INSTALL_DIR/procs"
else
    log_info "[$MODULE] Install directory matches symlink location, skipping symlink creation"
fi

log_info "[$MODULE] Installation completed successfully"