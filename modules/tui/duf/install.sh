#!/usr/bin/env bash
set -euo pipefail

source "${LIB_INSTALLER}/path.sh"
source "${LIB_INSTALLER}/symlink.sh"
source "${LIB_INSTALLER}/registry.sh"
source "${LIB_INSTALLER}/state.sh"

load_states "$CANONICAL_ID" || exit 1
ARCHIVE_FILE="$(get_state "ARCHIVE_FILE")" || exit 1

if [[ ! -f "$ARCHIVE_FILE" ]]; then
    tlog_error "install:$CANONICAL_ID" "Archive file not found: ${ARCHIVE_FILE}"

    exit 2
fi

if [[ -z "${DUF_INSTALL_DIR:-}" ]]; then
    DUF_INSTALL_DIR="$INSTALL_DIR/duf"
fi

SUDO_CMD=""
if ! can_write "$DUF_INSTALL_DIR"; then
    SUDO_CMD="sudo"
fi

if ! $SUDO_CMD mkdir -p "$DUF_INSTALL_DIR"; then
    tlog_error "install:$CANONICAL_ID" "Failed to create install directory: $DUF_INSTALL_DIR"

    exit 3
fi

if ! $SUDO_CMD tar --overwrite -xzf "$ARCHIVE_FILE" -C "$DUF_INSTALL_DIR"; then
    tlog_error "install:$CANONICAL_ID" "Extraction failed"

    exit 4
fi

if ! $SUDO_CMD chmod +x "$DUF_INSTALL_DIR/duf"; then
    tlog_error "install:$CANONICAL_ID" "Failed to make binary executable"

    exit 5
fi

tlog_info "install:$CANONICAL_ID" "Creating symbolic links"
if [[ "$DUF_INSTALL_DIR" != "$(symlink_location)" ]]; then
    symlink_binary "$CANONICAL_ID" "$DUF_INSTALL_DIR/duf"
else
    tlog_info "install:$CANONICAL_ID" "Install directory matches symlink location, skipping symlink creation"
fi

set_registry "INSTALL_PATH" "$DUF_INSTALL_DIR" || exit 6
save_registry "$CANONICAL_ID" || exit 6

tlog_info "install:$CANONICAL_ID" "Installation completed successfully"
