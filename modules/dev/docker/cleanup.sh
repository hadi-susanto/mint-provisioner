#!/usr/bin/env bash
set -euo pipefail

source "$LIB_COMMON/common.sh"
source "$LIB_INSTALLER/state.sh"

tlog_info "cleanup:$CANONICAL_ID" "Deleting installation states"

if ! delete_states "$CANONICAL_ID"; then
    tlog_error "cleanup:$CANONICAL_ID" "Failed to delete installation states"

    exit 1
fi

tlog_info "cleanup:$CANONICAL_ID" "Cleanup completed successfully"
