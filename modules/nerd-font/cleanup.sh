#!/usr/bin/env bash

#
# Performs post-install cleanup for Nerd Font.
#
# Actions:
#   - Removes the downloaded zip package.
#   - Removes the module state file.
#

source "${LIB_DIR}/common.sh"

MODULE="nerd-font"
STATE_FILE="${STATE_DIR}/nerd-font.path"
NAME_FILE="${STATE_DIR}/nerd-font.name"

log_info "[$MODULE] Looking for state file: ${STATE_FILE}"

if [[ ! -f "$STATE_FILE" ]] && [[ ! -f "$NAME_FILE" ]]; then
    log_warn "[$MODULE] State files not found, nothing to clean"
    exit 0
fi

if [[ -f "$STATE_FILE" ]]; then
    read -r DOWNLOADED_FILE < "$STATE_FILE"

    if [[ -f "$DOWNLOADED_FILE" ]]; then
        log_info "[$MODULE] Removing downloaded file: ${DOWNLOADED_FILE}"
        rm -f "$DOWNLOADED_FILE"
    fi

    log_info "[$MODULE] Removing state file: $STATE_FILE"
    rm -f "$STATE_FILE"
fi

if [[ -f "$NAME_FILE" ]]; then
    log_info "[$MODULE] Removing name file: $NAME_FILE"
    rm -f "$NAME_FILE"
fi

log_info "[$MODULE] Cleanup completed"
exit 0
