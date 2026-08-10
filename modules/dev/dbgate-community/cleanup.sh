#!/usr/bin/env bash
set -euo pipefail

source "$LIB_COMMON/common.sh"
source "$LIB_INSTALLER/state.sh"

if ! load_states "$CANONICAL_ID"; then
    tlog_warn "cleanup:$CANONICAL_ID" "State not found, skipping cleanup"

    exit 0
fi

DEB_FILE=""
if stored_file="$(get_state "DEB_FILE" 2>/dev/null)"; then
    DEB_FILE="$stored_file"
fi

if [[ -n "$DEB_FILE" && -f "$DEB_FILE" ]]; then
    tlog_info "cleanup:$CANONICAL_ID" \
        "Removing downloaded package: %s" "$DEB_FILE"
    rm -f "$DEB_FILE"
fi

tlog_info "cleanup:$CANONICAL_ID" "Deleting states"
delete_states "$CANONICAL_ID"

tlog_info "cleanup:$CANONICAL_ID" "Cleanup completed successfully"
