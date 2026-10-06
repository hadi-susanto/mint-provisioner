#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/stateful-extract-install.sh"

stateful_extract_install \
    "$CANONICAL_ID" \
    "ARCHIVE_FILE" \
    "zip" \
    "${JUNIE_INSTALL_DIR:-$INSTALL_DIR/junie}" \
    "junie-app/bin/junie" "junie" || exit $?
