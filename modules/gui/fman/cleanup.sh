#!/usr/bin/env bash
set -euo pipefail

source "${LIB_DIR}/common.sh"
source "${LIB_DIR}/state.sh"

if ! load_states "$CANONICAL_ID"; then
    log_warn "[$CANONICAL_ID] State not found, skipping cleanup"

    exit 0
fi

DEB_FILE="$(get_state "DEB_FILE")"

if [[ -n "$DEB_FILE" && -f "$DEB_FILE" ]]; then
    log_info "[$CANONICAL_ID] Removing package file: $DEB_FILE"
    rm -f "$DEB_FILE"
fi

log_info "[$CANONICAL_ID] Deleting states"
delete_states "$CANONICAL_ID"

log_info "[$CANONICAL_ID] Cleanup completed successfully"
