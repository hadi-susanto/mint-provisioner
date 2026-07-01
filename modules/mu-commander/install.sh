#!/usr/bin/env bash

source "${LIB_DIR}/installer_apt.sh"

MODULE="mu-commander"
STATE_FILE="${STATE_DIR}/mu-commander.path"

if [[ ! -f "$STATE_FILE" ]]; then
    log_error "[$MODULE] State file not found"

    exit 1
fi

read -r DEB_FILE < "$STATE_FILE"

if [[ ! -f "$DEB_FILE" ]]; then
    log_error "[$MODULE] Package file not found: ${DEB_FILE}"

    exit 2
fi

log_info "[$MODULE] Installing package: $DEB_FILE"

if ! apt_install "$DEB_FILE"; then
    log_error "[$MODULE] Package installation failed"

    exit 3
fi

exit 0
