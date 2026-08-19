#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/install-target.sh"

if ! command -v git >/dev/null 2>&1; then
    tlog_error "pre-install:$CANONICAL_ID" "git is required but not installed"

    exit 1
fi

install_dir="${POWERLEVEL10K_INSTALL_DIR:-$INSTALL_DIR/power-level-10k}"
valid_install_target "$CANONICAL_ID" "$install_dir" "POWERLEVEL10K_INSTALL_DIR"
