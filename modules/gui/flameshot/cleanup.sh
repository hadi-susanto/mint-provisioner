#!/usr/bin/env bash
set -euo pipefail

#
# Performs post-install cleanup for Flameshot.
#
# Actions:
#   - Removes the downloaded .deb package.
#   - Removes the module state file.
#
# Exit codes:
#   0 - Cleanup completed successfully
#   1 - State file not found
#   2 - Failed to remove .deb package
#   3 - Failed to remove state file
#

# shellcheck source=/dev/null
source "${LIB_COMMON}/common.sh"
source "${LIB_INSTALLER}/state.sh"

if ! load_states "$CANONICAL_ID"; then
    tlog_warn "cleanup:$CANONICAL_ID" "State not found, skipping cleanup"

    exit 0
fi

DEB_FILE="$(get_state "DEB_FILE")"

if [[ -n "$DEB_FILE" && -f "$DEB_FILE" ]]; then
    tlog_info "cleanup:$CANONICAL_ID" "Removing package file: $DEB_FILE"
    rm -f "$DEB_FILE"
fi

tlog_info "cleanup:$CANONICAL_ID" "Deleting states"
delete_states "$CANONICAL_ID"

tlog_info "cleanup:$CANONICAL_ID" "Cleanup completed successfully"

exit 0
