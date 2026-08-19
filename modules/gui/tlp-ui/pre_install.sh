#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/install-target.sh"

if ! command -v python3 >/dev/null 2>&1; then
    tlog_error "pre-install:$CANONICAL_ID" "python3 is required but not installed."

    exit 1
fi

if ! python3 -c 'import sys; raise SystemExit(sys.version_info < (3, 10))'; then
    tlog_error "pre-install:$CANONICAL_ID" "TLPUI requires Python 3.10 or newer."

    exit 1
fi

if ! command -v tlp >/dev/null 2>&1; then
    tlog_error "pre-install:$CANONICAL_ID" "TLP is required but not installed. Install it first using: ./install.sh cli/tlp"

    exit 1
fi

if ! command -v git >/dev/null 2>&1; then
    tlog_error "pre-install:$CANONICAL_ID" "git is required but not installed."

    exit 1
fi

install_dir="${TLP_UI_INSTALL_DIR:-$INSTALL_DIR/tlp-ui}"
valid_install_target "$CANONICAL_ID" "$install_dir" "ADB_INSTALL_DIR"
