#!/usr/bin/env bash
set -euo pipefail

source "${LIB_DIR}/common.sh"
source "${LIB_DIR}/state.sh"

log_info "[$CANONICAL_ID] Deleting states"
delete_states "$CANONICAL_ID"
