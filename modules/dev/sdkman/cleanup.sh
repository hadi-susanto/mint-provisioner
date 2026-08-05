#!/usr/bin/env bash
set -euo pipefail

source "$LIB_COMMON/common.sh"
source "$LIB_INSTALLER/state.sh"

TAG="cleanup:$CANONICAL_ID"

if ! load_states "$CANONICAL_ID"; then
    tlog_warn "$TAG" "State not found, skipping cleanup"

    exit 0
fi

# Standard and Native archives
for key in STANDARD_FILE NATIVE_FILE CANDIDATES_FILE; do
    file_path="$(get_state "$key")"
    if [[ -n "$file_path" && -f "$file_path" ]]; then
        tlog_info "$TAG" "Removing downloaded file: $file_path"
        rm -f "$file_path"
    fi
done

tlog_info "$TAG" "Deleting states"
delete_states "$CANONICAL_ID"

tlog_info "$TAG" "[$CANONICAL_ID] Cleanup completed successfully"
