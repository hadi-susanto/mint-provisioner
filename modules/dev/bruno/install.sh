#!/usr/bin/env bash
set -euo pipefail

source "${LIB_DIR}/installer_apt.sh"

log_info "[$CANONICAL_ID] Installing Bruno"

if ! apt_install bruno; then
    log_error "[$CANONICAL_ID] Bruno package installation failed"

    exit 1
fi

log_info "[$CANONICAL_ID] Bruno installed successfully"
