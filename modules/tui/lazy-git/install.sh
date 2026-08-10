#!/usr/bin/env bash
set -euo pipefail

source "${LIB_INSTALLER}/path.sh"
source "${LIB_INSTALLER}/symlink.sh"
source "${LIB_INSTALLER}/messages.sh"
source "${LIB_INSTALLER}/registry.sh"
source "${LIB_INSTALLER}/state.sh"

load_states "$CANONICAL_ID" || exit 1
ARCHIVE_FILE="$(get_state "ARCHIVE_FILE")" || exit 1

if [[ ! -f "$ARCHIVE_FILE" ]]; then
    tlog_error "install:$CANONICAL_ID" "Archive file not found: ${ARCHIVE_FILE}"

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
    tlog_error "install:$CANONICAL_ID" "Failed to create install directory: $LAZY_GIT_INSTALL_DIR"

    exit 3
fi

if ! $SUDO_CMD tar --overwrite -xzf "$ARCHIVE_FILE" -C "$LAZY_GIT_INSTALL_DIR"; then
    tlog_error "install:$CANONICAL_ID" "Extraction failed"

    exit 4
fi

if ! $SUDO_CMD chmod +x "$LAZY_GIT_INSTALL_DIR/lazygit"; then
    tlog_error "install:$CANONICAL_ID" "Failed to make binary executable"

    exit 5
fi

tlog_info "install:$CANONICAL_ID" "Creating symbolic links"
if [[ "$LAZY_GIT_INSTALL_DIR" != "$(symlink_location)" ]]; then
    symlink_binary "$CANONICAL_ID" "$LAZY_GIT_INSTALL_DIR/lazygit"
else
    tlog_info "install:$CANONICAL_ID" "Install directory matches symlink location, skipping symlink creation"
fi

set_registry "INSTALL_PATH" "$LAZY_GIT_INSTALL_DIR" || exit 6
save_registry "$CANONICAL_ID" || exit 6

tlog_info "install:$CANONICAL_ID" "Installation completed successfully"
