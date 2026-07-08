#!/usr/bin/env bash

source "${LIB_DIR}/common.sh"

MODULE="apache-maven"
STATE_FILE="${STATE_DIR}/${MODULE}.path"

if [[ -f "$STATE_FILE" ]]; then
    read -r ARCHIVE_FILE < "$STATE_FILE"
    if [[ -f "$ARCHIVE_FILE" ]]; then
        log_info "[$MODULE] Cleaning up downloaded archive: $ARCHIVE_FILE"
        rm -f "$ARCHIVE_FILE"
    fi
    rm -f "$STATE_FILE"
fi
