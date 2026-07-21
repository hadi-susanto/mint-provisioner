#!/usr/bin/env bash
set -euo pipefail

#
# Installs starship from a previously downloaded .tar.gz archive.
#

source "${LIB_DIR}/installer_common.sh"
source "${LIB_DIR}/messages.sh"
source "${LIB_DIR}/state.sh"

load_states "$CANONICAL_ID" || exit 1
ARCHIVE_FILE="$(get_state "ARCHIVE_FILE")" || exit 1

if [[ ! -f "$ARCHIVE_FILE" ]]; then
    log_error "[$CANONICAL_ID] Archive file not found: ${ARCHIVE_FILE}"

    exit 2
fi

if [[ -z "${STARSHIP_INSTALL_DIR:-}" ]]; then
    STARSHIP_INSTALL_DIR="$INSTALL_DIR/starship"
fi

log_info "[$CANONICAL_ID] Extracting content to $STARSHIP_INSTALL_DIR"

SUDO_CMD=""
if ! can_write "$STARSHIP_INSTALL_DIR"; then
    SUDO_CMD="sudo"
fi

if ! $SUDO_CMD mkdir -p "$STARSHIP_INSTALL_DIR"; then
    log_error "[$CANONICAL_ID] Failed to create install directory: $STARSHIP_INSTALL_DIR"

    exit 3
fi

# Extract. Using -C to change directory.
if ! $SUDO_CMD tar --overwrite -xzf "$ARCHIVE_FILE" -C "$STARSHIP_INSTALL_DIR"; then
    log_error "[$CANONICAL_ID] Extraction failed"

    exit 4
fi

if ! $SUDO_CMD chmod +x "$STARSHIP_INSTALL_DIR/starship"; then
    log_error "[$CANONICAL_ID] Failed to make binary executable"

    exit 5
fi

log_info "[$CANONICAL_ID] Creating symbolic links"
if [[ "$STARSHIP_INSTALL_DIR" != "$(symlink_location)" ]]; then
    symlink_binary "$CANONICAL_ID" "$STARSHIP_INSTALL_DIR/starship"
else
    log_info "[$CANONICAL_ID] Install directory matches symlink location, skipping symlink creation"
fi

log_info "[$CANONICAL_ID] Installation completed successfully"

msg="starship is require nerd-font to be installed, please ensure you have nerd font installed.
to install you can use mint-provisioner to install one."

add_message "$CANONICAL_ID" "info" "$msg"
