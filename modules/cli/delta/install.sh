#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/stateful-extract-install.sh"
source "$LIB_INSTALLER/messages.sh"

stateful_extract_install \
    "$CANONICAL_ID" \
    "ARCHIVE_FILE" \
    "tar" \
    "${DELTA_INSTALL_DIR:-$INSTALL_DIR/delta}" \
    "delta" \
    "delta" \
    -- \
    "--strip-components=1" || exit $?

add_system_toolkit_message "$CANONICAL_ID"
