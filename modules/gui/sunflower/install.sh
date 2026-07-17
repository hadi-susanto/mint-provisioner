#!/usr/bin/env bash

source "${LIB_DIR}/installer_apt.sh"
source "${LIB_DIR}/state.sh"

load_states "$CANONICAL_ID" || exit 1
DEB_FILE="$(get_state "DEB_FILE")" || exit 1

if [[ ! -f "$DEB_FILE" ]]; then
    log_error "[$CANONICAL_ID] Package file not found: ${DEB_FILE}"

    exit 2
fi

log_info "[$CANONICAL_ID] Installing package: $DEB_FILE"

if ! apt_install "$DEB_FILE"; then
    log_error "[$CANONICAL_ID] Package installation failed"

    exit 3
fi

exit 0
