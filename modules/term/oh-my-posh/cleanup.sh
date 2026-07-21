#!/usr/bin/env bash
set -euo pipefail

#
# Performs post-install cleanup for oh-my-posh.
#

source "${LIB_DIR}/common.sh"
source "${LIB_DIR}/state.sh"

if ! load_states "$CANONICAL_ID"; then
    log_warn "[$CANONICAL_ID] State not found, skipping cleanup"

    exit 0
fi

for key in BINARY_FILE THEMES_FILE; do
    file_path="$(get_state "$key")"
    if [[ -n "$file_path" && -f "$file_path" ]]; then
        log_info "[$CANONICAL_ID] Removing downloaded file: $file_path"
        rm -f "$file_path"
    fi
done

log_info "[$CANONICAL_ID] Deleting states"
delete_states "$CANONICAL_ID"

log_info "[$CANONICAL_ID] Cleanup completed successfully"
