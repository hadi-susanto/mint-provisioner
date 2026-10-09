#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/install-target.sh"

if ! command -v python3 >/dev/null 2>&1; then
    tlog_error "pre-install:$CANONICAL_ID" "python3 is required but not installed."

    exit 1
fi

install_dir="${PIPX_INSTALL_DIR:-$INSTALL_DIR/pipx}"
valid_install_target "$CANONICAL_ID" "$install_dir" "PIPX_INSTALL_DIR"
