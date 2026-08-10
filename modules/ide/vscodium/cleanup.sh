#!/usr/bin/env bash
set -euo pipefail

source "${LIB_COMMON}/common.sh"
source "${LIB_INSTALLER}/state.sh"

if ! load_states "$CANONICAL_ID"; then
    tlog_warn "$CANONICAL_ID" "State not found, skipping cleanup"

    exit 0
fi

deb_file="$(get_state "DEB_FILE")"

if [[ -n "$deb_file" && -f "$deb_file" ]]; then
    tlog_info "$CANONICAL_ID" "Removing downloaded package: %s" "$deb_file"
    rm -f "$deb_file"
fi

tlog_info "$CANONICAL_ID" "Deleting states"
delete_states "$CANONICAL_ID"

tlog_info "$CANONICAL_ID" "Cleanup completed successfully"
