#!/usr/bin/env bash

#
# Performs post-install cleanup for adb.
#

source "${LIB_DIR}/common.sh"
source "${LIB_DIR}/state.sh"

if ! load_states "$CANONICAL_ID"; then
    log_warn "[$CANONICAL_ID] State not found, skipping cleanup"

    exit 0
fi

ARCHIVE_FILE="$(get_state "ARCHIVE_FILE")"

if [[ -n "$ARCHIVE_FILE" && -f "$ARCHIVE_FILE" ]]; then
    log_info "[$CANONICAL_ID] Removing archive file: $ARCHIVE_FILE"
    rm -f "$ARCHIVE_FILE"
fi

log_info "[$CANONICAL_ID] Deleting states"
delete_states "$CANONICAL_ID"

log_info "[$CANONICAL_ID] Cleanup completed successfully"
