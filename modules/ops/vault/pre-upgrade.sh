#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/hashicorp-download.sh"

if ! command -v setcap >/dev/null 2>&1; then
    tlog_error "pre-upgrade:$CANONICAL_ID" "setcap is required to let Vault lock memory; install it with: sudo apt install libcap2-bin"

    exit 1
fi

hashicorp_download_binary "$CANONICAL_ID" "vault"
