#!/usr/bin/env bash
set -euo pipefail

#
# Installs oh-my-posh from previously downloaded artifacts.
#

source "${LIB_INSTALLER}/path.sh"
source "${LIB_INSTALLER}/symlink.sh"
source "${LIB_INSTALLER}/state.sh"
source "${LIB_INSTALLER}/messages.sh"
source "${LIB_INSTALLER}/registry.sh"

load_states "$CANONICAL_ID" || exit 1
BINARY_FILE="$(get_state "BINARY_FILE")" || exit 1
THEMES_FILE="$(get_state "THEMES_FILE")" || exit 1

if [[ ! -f "$BINARY_FILE" ]]; then
    tlog_error "install:$CANONICAL_ID" "Binary file not found: ${BINARY_FILE}"

    exit 2
fi

if [[ ! -f "$THEMES_FILE" ]]; then
    tlog_error "install:$CANONICAL_ID" "Themes file not found: ${THEMES_FILE}"

    exit 2
fi

if [[ -z "${OH_MY_POSH_INSTALL_DIR:-}" ]]; then
    OH_MY_POSH_INSTALL_DIR="$INSTALL_DIR/oh-my-posh"
fi

tlog_info "install:$CANONICAL_ID" "Installing binary to $OH_MY_POSH_INSTALL_DIR"

SUDO_CMD=""
if ! can_write "$OH_MY_POSH_INSTALL_DIR"; then
    SUDO_CMD="sudo"
fi

if ! $SUDO_CMD mkdir -p "$OH_MY_POSH_INSTALL_DIR"; then
    tlog_error "install:$CANONICAL_ID" "Failed to create install directory: $OH_MY_POSH_INSTALL_DIR"

    exit 3
fi

if ! $SUDO_CMD cp "$BINARY_FILE" "$OH_MY_POSH_INSTALL_DIR/oh-my-posh"; then
    tlog_error "install:$CANONICAL_ID" "Failed to copy binary"

    exit 4
fi

if ! $SUDO_CMD chmod +x "$OH_MY_POSH_INSTALL_DIR/oh-my-posh"; then
    tlog_error "install:$CANONICAL_ID" "Failed to make binary executable"

    exit 5
fi

if [[ -z "${OH_MY_POSH_THEMES_INSTALL_DIR:-}" ]]; then
    OH_MY_POSH_THEMES_INSTALL_DIR="$OH_MY_POSH_INSTALL_DIR/themes"
fi

tlog_info "install:$CANONICAL_ID" "Installing themes to $OH_MY_POSH_THEMES_INSTALL_DIR"

SUDO_CMD=""
if ! can_write "$OH_MY_POSH_THEMES_INSTALL_DIR"; then
    SUDO_CMD="sudo"
fi

if ! $SUDO_CMD mkdir -p "$OH_MY_POSH_THEMES_INSTALL_DIR"; then
    tlog_error "install:$CANONICAL_ID" "Failed to create themes directory: $OH_MY_POSH_THEMES_INSTALL_DIR"

    exit 6
fi

if ! $SUDO_CMD unzip -o "$THEMES_FILE" -d "$OH_MY_POSH_THEMES_INSTALL_DIR"; then
    tlog_error "install:$CANONICAL_ID" "Themes extraction failed"

    exit 7
fi

tlog_info "install:$CANONICAL_ID" "Creating symbolic link"

if [[ "$OH_MY_POSH_INSTALL_DIR" != "$(symlink_location)" ]]; then
    if ! symlink_binary "$CANONICAL_ID" "$OH_MY_POSH_INSTALL_DIR/oh-my-posh"; then
        tlog_error "install:$CANONICAL_ID" "Failed to create the Oh My Posh symbolic link"

        exit 8
    fi
else
    tlog_info "install:$CANONICAL_ID" \
        "Install directory matches symlink location, skipping symbolic link"
fi

set_registry "INSTALL_PATH" "$OH_MY_POSH_INSTALL_DIR" || exit 9
save_registry "$CANONICAL_ID" || exit 9

tlog_info "install:$CANONICAL_ID" "Installation completed successfully"

msg="Oh My Posh requires a Nerd Font to be installed. Ensure you
have a Nerd Font installed.
To install one, you can use mint-provisioner."

add_message "$CANONICAL_ID" "info" "$msg"

add_system_toolkit_message "$CANONICAL_ID"

msg="Unless System Toolkit is used to enable the shell
integration, configure Oh My Posh manually:
  https://ohmyposh.dev/docs/installation/prompt"

add_message "$CANONICAL_ID" "info" "$msg"
