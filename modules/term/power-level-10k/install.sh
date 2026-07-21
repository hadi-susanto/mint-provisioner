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

    exit 0
fi

if ! $SUDO_CMD mkdir -p "$POWERLEVEL10K_INSTALL_DIR"; then
    log_error "[$CANONICAL_ID] Failed to create parent directory for: $POWERLEVEL10K_INSTALL_DIR"

    exit 1
fi

REPO_URL="https://github.com/romkatv/powerlevel10k.git"
if ! $SUDO_CMD git clone --depth 1 "$REPO_URL" "$POWERLEVEL10K_INSTALL_DIR"; then
    log_error "[$CANONICAL_ID] Failed to clone repository: $REPO_URL"

    exit 2
fi

log_info "[$CANONICAL_ID] Installation completed successfully"

if command -v zsh >/dev/null 2>&1; then
    exit 0
fi

# Zsh not found, tell the user
msg="Zsh is not installed. You can install it using Mint Provisioner: './install.sh term/zsh'
Once installed, run './configure.sh term/power-level-10k' to integrate the existing installation."

log_warn "[$CANONICAL_ID] Zsh not found. Power Level 10k is Zsh theme, you will need Zsh for this to work."
add_message "$CANONICAL_ID" "warn" "$msg"
