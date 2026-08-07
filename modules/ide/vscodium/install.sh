#!/usr/bin/env bash
set -euo pipefail

source "${LIB_INSTALLER}/apt.sh"
source "${LIB_INSTALLER}/state.sh"

load_states "$CANONICAL_ID" || exit 1
deb_file="$(get_state "DEB_FILE")" || exit 1

if [[ ! -f "$deb_file" ]]; then
    tlog_error "$CANONICAL_ID" "Package file not found: %s" "$deb_file"

    exit 2
fi

if ! apt_install "$CANONICAL_ID" "$deb_file"; then
    tlog_error "$CANONICAL_ID" "Package installation failed"

    exit 3
fi

tlog_info "$CANONICAL_ID" "VSCodium installed successfully"
