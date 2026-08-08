#!/usr/bin/env bash
set -euo pipefail

#
# Performs post-install cleanup for lazy-git.
#

source "${LIB_COMMON}/common.sh"
source "${LIB_INSTALLER}/state.sh"

if ! load_states "$CANONICAL_ID"; then
    tlog_warn "cleanup:$CANONICAL_ID" "State not found, skipping cleanup"

    exit 0
fi

ARCHIVE_FILE="$(get_state "ARCHIVE_FILE")"

if [[ -n "$ARCHIVE_FILE" && -f "$ARCHIVE_FILE" ]]; then
    tlog_info "cleanup:$CANONICAL_ID" "Removing archive file: $ARCHIVE_FILE"
    rm -f "$ARCHIVE_FILE"
fi

tlog_info "cleanup:$CANONICAL_ID" "Deleting states"
delete_states "$CANONICAL_ID"

tlog_info "cleanup:$CANONICAL_ID" "Cleanup completed successfully"
