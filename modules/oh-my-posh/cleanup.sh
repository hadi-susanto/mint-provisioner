#!/usr/bin/env bash

#
# Performs post-install cleanup for oh-my-posh.
#

source "${LIB_DIR}/common.sh"

MODULE="oh-my-posh"
STATE_FILE_BINARY="${STATE_DIR}/oh-my-posh-binary.path"
STATE_FILE_THEMES="${STATE_DIR}/oh-my-posh-themes.path"

cleanup_file() {
    local state_file=$1
    if [[ -f "$state_file" ]]; then
        read -r download_file < "$state_file"
        if [[ -f "$download_file" ]]; then
            log_info "[$MODULE] Removing file: $download_file"
            rm -f "$download_file"
        fi
        log_info "[$MODULE] Removing state file: $state_file"
        rm -f "$state_file"
    fi
}

cleanup_file "$STATE_FILE_BINARY"
cleanup_file "$STATE_FILE_THEMES"

log_info "[$MODULE] Cleanup completed successfully"
