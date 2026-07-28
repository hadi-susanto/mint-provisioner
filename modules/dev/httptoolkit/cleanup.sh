#!/usr/bin/env bash
set -euo pipefail

source "${LIB_DIR}/common.sh"
source "${LIB_DIR}/state.sh"

if ! load_states "$CANONICAL_ID"; then
    log_warn "[$CANONICAL_ID] State not found, skipping cleanup"

    exit 0
fi

deb_file="$(get_state "DEB_FILE" "")"

if [[ -n "$deb_file" && -f "$deb_file" ]]; then
    log_info "[$CANONICAL_ID] Removing downloaded package: $deb_file"

    if ! rm -f "$deb_file"; then
        log_error "[$CANONICAL_ID] Failed to remove downloaded package: $deb_file"

        exit 1
    fi
fi

log_info "[$CANONICAL_ID] Deleting states"
delete_states "$CANONICAL_ID" || exit 2

log_info "[$CANONICAL_ID] Cleanup completed successfully"
