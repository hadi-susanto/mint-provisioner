#!/usr/bin/env bash
set -euo pipefail

source "$LIB_COMMON/common.sh"
source "$LIB_INSTALLER/state.sh"

tag="cleanup:$CANONICAL_ID"

if ! load_states "$CANONICAL_ID"; then
    tlog_warn "$tag" "State not found, skipping cleanup"

    exit 0
fi

if archive_dir="$(get_state "FONT_ARCHIVES")" && [[ -d "$archive_dir" ]]; then
    tlog_info "$tag" "Removing downloaded font archives: %s" "$archive_dir"

    if ! rm -rf -- "$archive_dir"; then
        tlog_error "$tag" "Failed to remove font archive directory: %s" "$archive_dir"
        delete_states "$CANONICAL_ID" || true

        exit 1
    fi
fi

delete_states "$CANONICAL_ID" || exit $?
tlog_info "$tag" "Cleanup completed successfully"
