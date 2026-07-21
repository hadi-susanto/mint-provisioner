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

if [[ -z "${DU_RUST_INSTALL_DIR:-}" ]]; then
    DU_RUST_INSTALL_DIR="$INSTALL_DIR/du-rust"
fi

SUDO_CMD=""
if ! can_write "$DU_RUST_INSTALL_DIR"; then
    SUDO_CMD="sudo"
fi

if ! $SUDO_CMD mkdir -p "$DU_RUST_INSTALL_DIR"; then
    log_error "[$CANONICAL_ID] Failed to create install directory: $DU_RUST_INSTALL_DIR"

    exit 3
fi

if ! $SUDO_CMD tar --overwrite -xzf "$ARCHIVE_FILE" -C "$DU_RUST_INSTALL_DIR" --strip-components=1; then
    log_error "[$CANONICAL_ID] Extraction failed"

    exit 4
fi

if ! $SUDO_CMD chmod +x "$DU_RUST_INSTALL_DIR/dust"; then
    log_error "[$CANONICAL_ID] Failed to make binary executable"

    exit 5
fi

log_info "[$CANONICAL_ID] Creating symbolic links"
if [[ "$DU_RUST_INSTALL_DIR" != "$(symlink_location)" ]]; then
    symlink_binary "$CANONICAL_ID" "$DU_RUST_INSTALL_DIR/dust"
else
    log_info "[$CANONICAL_ID] Install directory matches symlink location, skipping symlink creation"
fi

log_info "[$CANONICAL_ID] Installation completed successfully"
