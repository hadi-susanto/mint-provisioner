#!/usr/bin/env bash
source "$LIB_DIR/common.sh"

PAYLOAD_DIR="$(dirname "${BASH_SOURCE[0]}")/payload"

if [[ ! -d "$PAYLOAD_DIR" ]]; then
    log_error "Unable to perform system configuration, $PAYLOAD_DIR not exists, broken installation?"

    exit 1
fi

for script in "$PAYLOAD_DIR"/*.sh; do
    if [[ ! -f "$script" ]]; then
        continue
    fi

    log_info "Executing payload script: $(basename "$script")..."
    if run_script "$script"; then
        log_info "Successfully executed: $(basename "$script")"
    else
        log_error "Failed to execute: $(basename "$script")"
    fi
done
