#!/usr/bin/env bash
set -euo pipefail

#
# Performs post-install cleanup for oh-my-posh.
#

source "${LIB_COMMON}/common.sh"
source "${LIB_INSTALLER}/state.sh"

if ! load_states "$CANONICAL_ID"; then
    tlog_warn "cleanup:$CANONICAL_ID" "State not found, skipping cleanup"

    exit 0
fi

for key in BINARY_FILE THEMES_FILE; do
    file_path="$(get_state "$key")"
    if [[ -n "$file_path" && -f "$file_path" ]]; then
        tlog_info "cleanup:$CANONICAL_ID" "Removing downloaded file: $file_path"
        rm -f "$file_path"
    fi
done

tlog_info "cleanup:$CANONICAL_ID" "Deleting states"
delete_states "$CANONICAL_ID"

tlog_info "cleanup:$CANONICAL_ID" "Cleanup completed successfully"
