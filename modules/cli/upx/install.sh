#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/stateful-extract-install.sh"

stateful_extract_install \
    "$CANONICAL_ID" \
    "ARCHIVE_FILE" \
    "tar" \
    "${UPX_INSTALL_DIR:-$INSTALL_DIR/upx}" \
    "upx" \
    "upx" \
    -- \
    "--strip-components=1" || exit $?
