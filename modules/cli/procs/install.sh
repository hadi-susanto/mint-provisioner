#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/stateful-extract-install.sh"
source "$LIB_INSTALLER/messages.sh"

stateful_extract_install \
    "$CANONICAL_ID" \
    "ARCHIVE_FILE" \
    "zip" \
    "${PROCS_INSTALL_DIR:-$INSTALL_DIR/procs}" \
    "procs" \
    "procs"
