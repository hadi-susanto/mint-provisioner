#!/usr/bin/env bash
set -euo pipefail

source "${LIB_DIR}/installer_apt.sh"
source "${LIB_DIR}/state.sh"

load_states "$CANONICAL_ID" || exit 1
deb_file="$(get_state "DEB_FILE")" || exit 1

if [[ ! -f "$deb_file" ]]; then
    log_error "[$CANONICAL_ID] Package file not found: $deb_file"

    exit 2
fi

if ! apt_install "$deb_file"; then
    log_error "[$CANONICAL_ID] Package installation failed"

    exit 3
fi

log_info "[$CANONICAL_ID] Yaak installed successfully"
