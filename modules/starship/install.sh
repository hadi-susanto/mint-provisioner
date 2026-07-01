#!/usr/bin/env bash

#
# Installs starship from a previously downloaded .tar.gz archive.
#

source "${LIB_DIR}/installer_common.sh"

MODULE="starship"
STATE_FILE="${STATE_DIR}/starship.path"

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

if [[ -z "${STARSHIP_INSTALL_DIR:-}" ]]; then
    STARSHIP_INSTALL_DIR="$INSTALL_DIR/starship"
fi

log_info "[$MODULE] Extracting content to $STARSHIP_INSTALL_DIR"

SUDO_CMD=""
if ! can_write "$(dirname "$STARSHIP_INSTALL_DIR")"; then
    SUDO_CMD="sudo"
fi

if ! $SUDO_CMD mkdir -p "$STARSHIP_INSTALL_DIR"; then
    log_error "[$MODULE] Failed to create install directory: $STARSHIP_INSTALL_DIR"

    exit 3
fi

# Extract. Using -C to change directory.
if ! $SUDO_CMD tar --overwrite -xzf "$ARCHIVE_FILE" -C "$STARSHIP_INSTALL_DIR"; then
    log_error "[$MODULE] Extraction failed"

    exit 4
fi

if ! $SUDO_CMD chmod +x "$STARSHIP_INSTALL_DIR/starship"; then
    log_error "[$MODULE] Failed to make binary executable"

    exit 5
fi

log_info "[$MODULE] Creating symbolic links"
if [[ "$STARSHIP_INSTALL_DIR" != "$(symlink_location)" ]]; then
    symlink_binary "$MODULE" "$STARSHIP_INSTALL_DIR/starship"
else
    log_info "[$MODULE] Install directory matches symlink location, skipping symlink creation"
fi

log_info "[$MODULE] Installation completed successfully"
