#!/usr/bin/env bash
set -euo pipefail

source "${LIB_COMMON}/common.sh"
source "${LIB_INSTALLER}/state.sh"

log_info "[$CANONICAL_ID] Deleting states"
delete_states "$CANONICAL_ID"
