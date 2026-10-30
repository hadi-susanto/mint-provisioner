#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/stateful-extract-install.sh"

stateful_extract_install \
    "$CANONICAL_ID" \
    "ARCHIVE_FILE" \
    "tar" \
    "${K9S_INSTALL_DIR:-$INSTALL_DIR/k9s}" \
    "k9s" \
    "k9s" || exit $?
