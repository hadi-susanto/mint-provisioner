#!/usr/bin/env bash
set -euo pipefail

source "${LIB_DIR}/common.sh"
source "${LIB_DIR}/state.sh"

log_info "[$CANONICAL_ID] Deleting installation states"

if ! delete_states "$CANONICAL_ID"; then
    log_error "[$CANONICAL_ID] Failed to delete installation states"

    exit 1
fi

log_info "[$CANONICAL_ID] Cleanup completed successfully"
