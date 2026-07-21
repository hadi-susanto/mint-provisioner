#!/usr/bin/env bash
set -euo pipefail

source "${LIB_DIR}/installer_common.sh"
source "${LIB_DIR}/state.sh"

load_states "$CANONICAL_ID" || exit 1
ARCHIVE_FILE="$(get_state "ARCHIVE_FILE")" || exit 1

if [[ ! -f "$ARCHIVE_FILE" ]]; then
    log_error "[$CANONICAL_ID] Archive file not found: ${ARCHIVE_FILE}"

    exit 2
fi

if [[ -z "${LAZY_GIT_INSTALL_DIR:-}" ]]; then
    LAZY_GIT_INSTALL_DIR="$INSTALL_DIR/lazy-git"
fi

SUDO_CMD=""
if ! can_write "$LAZY_GIT_INSTALL_DIR"; then
    SUDO_CMD="sudo"
fi

if ! $SUDO_CMD mkdir -p "$LAZY_GIT_INSTALL_DIR"; then
    log_error "[$CANONICAL_ID] Failed to create install directory: $LAZY_GIT_INSTALL_DIR"

    exit 3
fi

if ! $SUDO_CMD tar --overwrite -xzf "$ARCHIVE_FILE" -C "$LAZY_GIT_INSTALL_DIR"; then
    log_error "[$CANONICAL_ID] Extraction failed"

    exit 4
fi

if ! $SUDO_CMD chmod +x "$LAZY_GIT_INSTALL_DIR/lazygit"; then
    log_error "[$CANONICAL_ID] Failed to make binary executable"

    exit 5
fi

log_info "[$CANONICAL_ID] Creating symbolic links"
if [[ "$LAZY_GIT_INSTALL_DIR" != "$(symlink_location)" ]]; then
    symlink_binary "$CANONICAL_ID" "$LAZY_GIT_INSTALL_DIR/lazygit"
else
    log_info "[$CANONICAL_ID] Install directory matches symlink location, skipping symlink creation"
fi

log_info "[$CANONICAL_ID] Installation completed successfully"
