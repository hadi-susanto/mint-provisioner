#!/usr/bin/env bash
set -euo pipefail

source "$LIB_COMMON/common.sh"
source "$LIB_INSTALLER/state.sh"

if ! load_states "$CANONICAL_ID"; then
    tlog_warn "cleanup:$CANONICAL_ID" "State not found, skipping cleanup"

    exit 0
fi

deb_file=""
if stored_file="$(get_state "DEB_FILE" 2>/dev/null)"; then
    deb_file="$stored_file"
fi

if [[ -n "$deb_file" && -f "$deb_file" ]]; then
    tlog_info "cleanup:$CANONICAL_ID" \
        "Removing downloaded package: %s" "$deb_file"

    if ! rm -f "$deb_file"; then
        tlog_error "cleanup:$CANONICAL_ID" \
            "Failed to remove downloaded package: %s" "$deb_file"

        exit 1
    fi
fi

tlog_info "cleanup:$CANONICAL_ID" "Deleting states"
delete_states "$CANONICAL_ID" || exit 2

tlog_info "cleanup:$CANONICAL_ID" "Cleanup completed successfully"
