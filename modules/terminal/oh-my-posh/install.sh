#!/usr/bin/env bash

#
# Installs oh-my-posh from previously downloaded artifacts.
#

source "${LIB_DIR}/common.sh"

MODULE="oh-my-posh"
STATE_FILE_BINARY="${STATE_DIR}/oh-my-posh-binary.path"
STATE_FILE_THEMES="${STATE_DIR}/oh-my-posh-themes.path"

log_info "[$MODULE] Looking for state file: ${STATE_FILE_BINARY} and ${STATE_FILE_THEMES}"

if [[ ! -f "$STATE_FILE_BINARY" ]] || [[ ! -f "$STATE_FILE_THEMES" ]]; then
    log_error "[$MODULE] State files not found"

    exit 1
fi

read -r BINARY_FILE < "$STATE_FILE_BINARY"
read -r THEMES_FILE < "$STATE_FILE_THEMES"

if [[ ! -f "$BINARY_FILE" ]]; then
    log_error "[$MODULE] Binary file not found: ${BINARY_FILE}"

    exit 2
fi

if [[ ! -f "$THEMES_FILE" ]]; then
    log_error "[$MODULE] Themes file not found: ${THEMES_FILE}"

    exit 2
fi

if [[ -z "${OH_MY_POSH_INSTALL_DIR:-}" ]]; then
    OH_MY_POSH_INSTALL_DIR="$INSTALL_DIR/oh-my-posh"
fi

log_info "[$MODULE] Installing binary to $OH_MY_POSH_INSTALL_DIR"

SUDO_CMD=""
if ! can_write "$OH_MY_POSH_INSTALL_DIR"; then
    SUDO_CMD="sudo"
fi

if ! $SUDO_CMD mkdir -p "$OH_MY_POSH_INSTALL_DIR"; then
    log_error "[$MODULE] Failed to create install directory: $OH_MY_POSH_INSTALL_DIR"

    exit 3
fi

if ! $SUDO_CMD cp "$BINARY_FILE" "$OH_MY_POSH_INSTALL_DIR/oh-my-posh"; then
    log_error "[$MODULE] Failed to copy binary"

    exit 4
fi

if ! $SUDO_CMD chmod +x "$OH_MY_POSH_INSTALL_DIR/oh-my-posh"; then
    log_error "[$MODULE] Failed to make binary executable"

    exit 5
fi

if [[ -z "${OH_MY_POSH_THEMES_INSTALL_DIR:-}" ]]; then
    OH_MY_POSH_THEMES_INSTALL_DIR="$OH_MY_POSH_INSTALL_DIR/themes"
fi

log_info "[$MODULE] Installing themes to $OH_MY_POSH_THEMES_INSTALL_DIR"

SUDO_CMD=""
if ! can_write "$OH_MY_POSH_THEMES_INSTALL_DIR"; then
    SUDO_CMD="sudo"
fi

if ! $SUDO_CMD mkdir -p "$OH_MY_POSH_THEMES_INSTALL_DIR"; then
    log_error "[$MODULE] Failed to create themes directory: $OH_MY_POSH_THEMES_INSTALL_DIR"

    exit 6
fi

if ! $SUDO_CMD unzip -o "$THEMES_FILE" -d "$OH_MY_POSH_THEMES_INSTALL_DIR"; then
    log_error "[$MODULE] Themes extraction failed"

    exit 7
fi

log_info "[$MODULE] Creating symbolic links"
sudo ln -sf "$OH_MY_POSH_INSTALL_DIR/oh-my-posh" /usr/local/bin/

log_info "[$MODULE] Installation completed successfully"
post_message "$MODULE" "Oh My Posh is require nerd-font to be installed, please ensure you have nerd font installed."
post_message "$MODULE" "to install you can use mint-provisioner to install one."
