#!/usr/bin/env bash
set -euo pipefail

source "${LIB_DIR}/common.sh"

if ! command -v python3 >/dev/null 2>&1; then
    log_error "[$CANONICAL_ID] python3 is required but not installed."

    exit 1
fi

if ! python3 -c 'import sys; raise SystemExit(sys.version_info < (3, 10))'; then
    log_error "[$CANONICAL_ID] TLPUI requires Python 3.10 or newer."

    exit 2
fi

if ! command -v tlp >/dev/null 2>&1; then
    log_error "[$CANONICAL_ID] TLP is required but not installed. Install it first using: ./install.sh cli/tlp"

    exit 3
fi

if ! command -v git >/dev/null 2>&1; then
    log_error "[$CANONICAL_ID] git is required but not installed."

    exit 4
fi
