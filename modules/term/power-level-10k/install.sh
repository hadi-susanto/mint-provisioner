#!/usr/bin/env bash
set -euo pipefail

#
# Installs power-level-10k by cloning the git repository.
#

source "${LIB_DIR}/common.sh"
source "${LIB_DIR}/messages.sh"

if [[ -z "${POWERLEVEL10K_INSTALL_DIR:-}" ]]; then
    POWERLEVEL10K_INSTALL_DIR="$INSTALL_DIR/power-level-10k"
fi

log_info "[$CANONICAL_ID] Installing to $POWERLEVEL10K_INSTALL_DIR"

SUDO_CMD=""
if ! can_write "$POWERLEVEL10K_INSTALL_DIR"; then
    SUDO_CMD="sudo"
fi

if [[ -d "$POWERLEVEL10K_INSTALL_DIR" ]]; then
    log_warn "[$CANONICAL_ID] Target directory already exists, skipping clone: $POWERLEVEL10K_INSTALL_DIR"
else
    if ! $SUDO_CMD mkdir -p "$POWERLEVEL10K_INSTALL_DIR"; then
        log_error "[$CANONICAL_ID] Failed to create install directory: $POWERLEVEL10K_INSTALL_DIR"

        exit 1
    fi

    REPO_URL="https://github.com/romkatv/powerlevel10k.git"
    if ! $SUDO_CMD git clone --depth 1 "$REPO_URL" "$POWERLEVEL10K_INSTALL_DIR"; then
        log_error "[$CANONICAL_ID] Failed to clone repository: $REPO_URL"

        exit 2
    fi
fi

log_info "[$CANONICAL_ID] Installation completed successfully"

printf -v install_dir_literal '%q' "$POWERLEVEL10K_INSTALL_DIR"
printf -v theme_file_literal '%q' "$POWERLEVEL10K_INSTALL_DIR/powerlevel10k.zsh-theme"

msg="To enable Powerlevel10k through System Toolkit, run:

  POWERLEVEL10K_INSTALL_DIR=$install_dir_literal syskit-cfg install term/power-level-10k

Without System Toolkit, add the following to your Zsh configuration:

  source $theme_file_literal"

add_message "$CANONICAL_ID" "info" "$msg"

if ! command -v zsh >/dev/null 2>&1; then
    msg="Zsh is not installed. Install it before enabling Powerlevel10k.
You can install Zsh using Mint Provisioner: './install.sh term/zsh'"

    log_warn "[$CANONICAL_ID] Zsh not found. Powerlevel10k requires Zsh."
    add_message "$CANONICAL_ID" "warn" "$msg"
fi
