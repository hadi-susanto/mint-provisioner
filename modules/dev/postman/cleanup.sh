#!/usr/bin/env bash
set -euo pipefail

source "$LIB_COMMON/common.sh"
source "$LIB_INSTALLER/state.sh"

if ! load_states "$CANONICAL_ID"; then
    tlog_warn "cleanup:$CANONICAL_ID" "State not found, skipping cleanup"

    exit 0
fi

archive_file=""
if stored_file="$(get_state "ARCHIVE_FILE" 2>/dev/null)"; then
    archive_file="$stored_file"
fi

if [[ -n "$archive_file" && -f "$archive_file" ]]; then
    tlog_info "cleanup:$CANONICAL_ID" \
        "Removing downloaded archive: %s" "$archive_file"

    if ! rm -f "$archive_file"; then
        tlog_error "cleanup:$CANONICAL_ID" \
            "Failed to remove downloaded archive: %s" "$archive_file"

        exit 1
    fi
fi

tlog_info "cleanup:$CANONICAL_ID" "Deleting states"
delete_states "$CANONICAL_ID" || exit 2

tlog_info "cleanup:$CANONICAL_ID" "Cleanup completed successfully"
