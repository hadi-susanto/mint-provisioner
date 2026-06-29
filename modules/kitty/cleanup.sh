#!/usr/bin/env bash

#
# Performs post-install cleanup for kitty.
#

source "${LIB_DIR}/common.sh"

MODULE="kitty"
STATE_FILE="${STATE_DIR}/kitty.path"

if [[ ! -f "$STATE_FILE" ]]; then
    log_warn "[$MODULE] State file not found, skipping cleanup"
    exit 0
fi

read -r ARCHIVE_FILE < "$STATE_FILE"

if [[ -f "$ARCHIVE_FILE" ]]; then
    log_info "[$MODULE] Removing archive file: $ARCHIVE_FILE"
    rm -f "$ARCHIVE_FILE"
fi

log_info "[$MODULE] Removing state file"
rm -f "$STATE_FILE"

log_info "[$MODULE] Cleanup completed successfully"
