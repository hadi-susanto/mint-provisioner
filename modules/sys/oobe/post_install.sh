#!/usr/bin/env bash

source "$LIB_DIR/common.sh"

SCRIPT_DIR="${MODULES_DIR}/${CANONICAL_ID}"
PAYLOAD_DIR="${SCRIPT_DIR}/payload"

if [[ ! -d "$PAYLOAD_DIR" ]]; then
    log_error "Unable to perform system configuration, $PAYLOAD_DIR not exists, broken installation?"

    exit 1
fi

for script in "$PAYLOAD_DIR"/*.sh; do
    if [[ ! -f "$script" ]]; then
        continue
    fi

    log_info "Executing payload script: ${script##*/}..."
    if run_script "$script"; then
        log_info "Successfully executed: ${script##*/}"
    else
        log_error "Failed to execute: ${script##*/}"
    fi
done
