#!/usr/bin/env bash

#
# Performs post-install cleanup for SDKMAN!
#

source "${LIB_DIR}/common.sh"

MODULE="sdkman"
STATE_FILES=(
    "${STATE_DIR}/sdkman.path"
    "${STATE_DIR}/sdkman-native.path"
    "${STATE_DIR}/sdkman.version"
    "${STATE_DIR}/sdkman-native.version"
    "${STATE_DIR}/sdkman-candidates.path"
)

for state_file in "${STATE_FILES[@]}"; do
    if [[ ! -f "$state_file" ]]; then
        continue
    fi

    # For .path files, we also need to remove the actual downloaded file
    if [[ "$state_file" == *".path" ]]; then
        read -r downloaded_file < "$state_file"
        if [[ -f "$downloaded_file" ]]; then
            log_info "[$MODULE] Removing downloaded file: $downloaded_file"
            rm -f "$downloaded_file"
        fi
    fi

    log_info "[$MODULE] Removing state file: $state_file"
    rm -f "$state_file"
done

log_info "[$MODULE] Cleanup completed successfully"
