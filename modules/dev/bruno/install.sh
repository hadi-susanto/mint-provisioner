#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/apt.sh"

tlog_info "install:$CANONICAL_ID" "Installing Bruno"

if ! apt_install "$CANONICAL_ID" bruno; then
    tlog_error "install:$CANONICAL_ID" "Bruno package installation failed"

    exit 1
fi

tlog_info "install:$CANONICAL_ID" "Bruno installed successfully"
