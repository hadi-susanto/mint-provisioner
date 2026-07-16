#!/usr/bin/env bash

#
# Installs oh-my-posh from previously downloaded artifacts.
#

source "${LIB_DIR}/common.sh"
source "${LIB_DIR}/messages.sh"
source "${LIB_DIR}/state.sh"

load_states "$CANONICAL_ID" || exit 1
BINARY_FILE="$(get_state "BINARY_FILE")" || exit 1
THEMES_FILE="$(get_state "THEMES_FILE")" || exit 1

if [[ ! -f "$BINARY_FILE" ]]; then
    log_error "[$CANONICAL_ID] Binary file not found: ${BINARY_FILE}"

    exit 2
fi

if [[ ! -f "$THEMES_FILE" ]]; then
    log_error "[$CANONICAL_ID] Themes file not found: ${THEMES_FILE}"

    exit 2
fi

if [[ -z "${OH_MY_POSH_INSTALL_DIR:-}" ]]; then
    OH_MY_POSH_INSTALL_DIR="$INSTALL_DIR/oh-my-posh"
fi

log_info "[$CANONICAL_ID] Installing binary to $OH_MY_POSH_INSTALL_DIR"

SUDO_CMD=""
if ! can_write "$OH_MY_POSH_INSTALL_DIR"; then
    SUDO_CMD="sudo"
fi

if ! $SUDO_CMD mkdir -p "$OH_MY_POSH_INSTALL_DIR"; then
    log_error "[$CANONICAL_ID] Failed to create install directory: $OH_MY_POSH_INSTALL_DIR"

    exit 3
fi

if ! $SUDO_CMD cp "$BINARY_FILE" "$OH_MY_POSH_INSTALL_DIR/oh-my-posh"; then
    log_error "[$CANONICAL_ID] Failed to copy binary"

    exit 4
fi

if ! $SUDO_CMD chmod +x "$OH_MY_POSH_INSTALL_DIR/oh-my-posh"; then
    log_error "[$CANONICAL_ID] Failed to make binary executable"

    exit 5
fi

if [[ -z "${OH_MY_POSH_THEMES_INSTALL_DIR:-}" ]]; then
    OH_MY_POSH_THEMES_INSTALL_DIR="$OH_MY_POSH_INSTALL_DIR/themes"
fi

log_info "[$CANONICAL_ID] Installing themes to $OH_MY_POSH_THEMES_INSTALL_DIR"

SUDO_CMD=""
if ! can_write "$OH_MY_POSH_THEMES_INSTALL_DIR"; then
    SUDO_CMD="sudo"
fi

if ! $SUDO_CMD mkdir -p "$OH_MY_POSH_THEMES_INSTALL_DIR"; then
    log_error "[$CANONICAL_ID] Failed to create themes directory: $OH_MY_POSH_THEMES_INSTALL_DIR"

    exit 6
fi

if ! $SUDO_CMD unzip -o "$THEMES_FILE" -d "$OH_MY_POSH_THEMES_INSTALL_DIR"; then
    log_error "[$CANONICAL_ID] Themes extraction failed"

    exit 7
fi

log_info "[$CANONICAL_ID] Creating symbolic links"
sudo ln -sf "$OH_MY_POSH_INSTALL_DIR/oh-my-posh" /usr/local/bin/

log_info "[$CANONICAL_ID] Installation completed successfully"

msg="Oh My Posh is require nerd-font to be installed, please ensure you have nerd font installed.
to install you can use mint-provisioner to install one."

add_message "$CANONICAL_ID" "info" "$msg"
