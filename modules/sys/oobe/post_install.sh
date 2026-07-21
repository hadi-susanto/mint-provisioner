#!/usr/bin/env bash
set -euo pipefail

source "$LIB_DIR/common.sh"

SCRIPT_DIR="${MODULES_DIR}/${CANONICAL_ID}"
PAYLOAD_DIR="${SCRIPT_DIR}/payload"

if [[ "${OOBE_SKIP_CONFIGURATION:-${SKIP_CONFIGURATION:-false}}" == "true" ]]; then
    log_warn "[$CANONICAL_ID] Skipping configuration as requested"

    exit 0
fi

if [[ ! -d "$PAYLOAD_DIR" ]]; then
    log_error "[$CANONICAL_ID] Payload directory does not exist: $PAYLOAD_DIR"

    exit 1
fi

failed=false

for script in "$PAYLOAD_DIR"/*.sh; do
    [[ -f "$script" ]] || continue

    log_info "[$CANONICAL_ID] Executing payload script: ${script##*/}"
    if run_script "$script"; then
        log_info "[$CANONICAL_ID] Successfully executed: ${script##*/}"
    else
        log_error "[$CANONICAL_ID] Failed to execute: ${script##*/}"
        failed=true
    fi
done

if [[ "$failed" == "true" ]]; then
    exit 2
fi
