#!/usr/bin/env bash
set -euo pipefail

source "${MODULES_DIR}/ide/jetbrains.sh"
source "${LIB_DIR}/state.sh"

if ! load_states "$CANONICAL_ID"; then
    log_warn "[$CANONICAL_ID] State not found, skipping cleanup"

    exit 0
fi

archive_file="$(get_state "JETBRAINS_ARCHIVE_FILE" 2>/dev/null || true)"

jetbrains_cleanup "$CANONICAL_ID" "$archive_file" || exit $?
delete_states "$CANONICAL_ID"
