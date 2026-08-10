#!/usr/bin/env bash
set -euo pipefail

#
# Installs starship from a previously downloaded .tar.gz archive.
#

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

if [[ -z "${STARSHIP_INSTALL_DIR:-}" ]]; then
    STARSHIP_INSTALL_DIR="$INSTALL_DIR/starship"
fi

tlog_info "install:$CANONICAL_ID" "Extracting content to $STARSHIP_INSTALL_DIR"

SUDO_CMD=""
if ! can_write "$STARSHIP_INSTALL_DIR"; then
    SUDO_CMD="sudo"
fi

if ! $SUDO_CMD mkdir -p "$STARSHIP_INSTALL_DIR"; then
    tlog_error "install:$CANONICAL_ID" "Failed to create install directory: $STARSHIP_INSTALL_DIR"

    exit 3
fi

# Extract. Using -C to change directory.
if ! $SUDO_CMD tar --overwrite -xzf "$ARCHIVE_FILE" -C "$STARSHIP_INSTALL_DIR"; then
    tlog_error "install:$CANONICAL_ID" "Extraction failed"

    exit 4
fi

if ! $SUDO_CMD chmod +x "$STARSHIP_INSTALL_DIR/starship"; then
    tlog_error "install:$CANONICAL_ID" "Failed to make binary executable"

    exit 5
fi

tlog_info "install:$CANONICAL_ID" "Creating symbolic links"
if [[ "$STARSHIP_INSTALL_DIR" != "$(symlink_location)" ]]; then
    symlink_binary "$CANONICAL_ID" "$STARSHIP_INSTALL_DIR/starship"
else
    tlog_info "install:$CANONICAL_ID" "Install directory matches symlink location, skipping symlink creation"
fi

set_registry "INSTALL_PATH" "$STARSHIP_INSTALL_DIR" || exit 6
save_registry "$CANONICAL_ID" || exit 6

tlog_info "install:$CANONICAL_ID" "Installation completed successfully"

msg="Starship requires a Nerd Font to be installed. Ensure you
have a Nerd Font installed.
To install one, you can use mint-provisioner."

add_message "$CANONICAL_ID" "info" "$msg"

add_system_toolkit_message "$CANONICAL_ID"

msg="Unless System Toolkit is used to enable the shell
integration, follow the 'Add the init script to your
shell's config file' section:
  https://starship.rs/"

add_message "$CANONICAL_ID" "info" "$msg"
