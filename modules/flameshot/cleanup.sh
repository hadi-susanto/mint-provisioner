#!/usr/bin/env bash

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
source "${LIB_DIR}/common.sh"

MODULE="flameshot"
STATE_FILE="${STATE_DIR}/flameshot.path"

log_info "[$MODULE] Looking for state file: ${STATE_FILE}"

if [[ ! -f "$STATE_FILE" ]]; then
    log_error "[$MODULE] State file not found"
    exit 1
fi

log_info "[$MODULE] Reading package path from state file"

read -r DEB_FILE < "$STATE_FILE"

log_info "[$MODULE] Package path: ${DEB_FILE}"

if [[ -f "$DEB_FILE" ]]; then
    log_info "[$MODULE] Removing package file"

    if ! rm -f "$DEB_FILE"; then
        log_warn "[$MODULE] Failed to remove package file"
        exit 2
    fi

    log_info "[$MODULE] Package file removed"
else
    log_warn "[$MODULE] Package file already removed: ${DEB_FILE}"
fi

log_info "[$MODULE] Removing state file"

if ! rm -f "$STATE_FILE"; then
    log_error "[$MODULE] Failed to remove state file"
    exit 3
fi

log_info "[$MODULE] State file removed"
log_info "[$MODULE] Cleanup completed successfully"

exit 0
