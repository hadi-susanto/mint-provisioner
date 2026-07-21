#!/usr/bin/env bash
set -euo pipefail

source "${LIB_DIR}/common.sh"
source "${LIB_DIR}/state.sh"

if ! load_states "$CANONICAL_ID"; then
    log_warn "[$CANONICAL_ID] State not found, skipping cleanup"

    exit 0
fi

ARCHIVE_FILE="$(get_state "ARCHIVE_FILE")"

if [[ -n "$ARCHIVE_FILE" && -f "$ARCHIVE_FILE" ]]; then
    log_info "[$CANONICAL_ID] Cleaning up downloaded archive: $ARCHIVE_FILE"
    rm -f "$ARCHIVE_FILE"
fi

log_info "[$CANONICAL_ID] Deleting states"
delete_states "$CANONICAL_ID"
