#!/usr/bin/env bash

#
# Installs power-level-10k by cloning the git repository.
#

source "${LIB_DIR}/common.sh"

MODULE="power-level-10k"
if [[ -z "${POWERLEVEL10K_INSTALL_DIR:-}" ]]; then
    POWERLEVEL10K_INSTALL_DIR="$INSTALL_DIR/power-level-10k"
fi

log_info "[$MODULE] Installing to $POWERLEVEL10K_INSTALL_DIR"

SUDO_CMD=""
if ! can_write "$(dirname "$(dirname "$POWERLEVEL10K_INSTALL_DIR")")"; then
    SUDO_CMD="sudo"
fi

if ! $SUDO_CMD mkdir -p "$(dirname "$POWERLEVEL10K_INSTALL_DIR")"; then
    log_error "[$MODULE] Failed to create parent directory for: $POWERLEVEL10K_INSTALL_DIR"

    exit 1
fi

if [[ -d "$POWERLEVEL10K_INSTALL_DIR" ]]; then
    log_warn "[$MODULE] Target directory already exists, skipping clone: $POWERLEVEL10K_INSTALL_DIR"

    exit 0
fi

if ! $SUDO_CMD git clone --depth 1 "$REPO_URL" "$POWERLEVEL10K_INSTALL_DIR"; then
    log_error "[$MODULE] Failed to clone repository: $REPO_URL"

    exit 2
fi

log_info "[$MODULE] Installation completed successfully"
