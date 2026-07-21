#!/usr/bin/env bash
set -euo pipefail

#
# Performs post-install cleanup for Nerd Font.
#
# Actions:
#   - Removes the downloaded zip package.
#   - Removes the module state file.
#

source "${LIB_DIR}/common.sh"
source "${LIB_DIR}/state.sh"

if ! load_states "$CANONICAL_ID"; then
    log_warn "[$CANONICAL_ID] State not found, skipping cleanup"

    exit 0
fi

DOWNLOADED_FILE="$(get_state "DOWNLOAD_FILE")"

if [[ -n "$DOWNLOADED_FILE" && -f "$DOWNLOADED_FILE" ]]; then
    log_info "[$CANONICAL_ID] Removing downloaded file: ${DOWNLOADED_FILE}"
    rm -f "$DOWNLOADED_FILE"
fi

log_info "[$CANONICAL_ID] Deleting states"
delete_states "$CANONICAL_ID"

log_info "[$CANONICAL_ID] Cleanup completed"
exit 0
