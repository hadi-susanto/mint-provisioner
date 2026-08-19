#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/stateful-extract-install.sh"

stateful_extract_install \
    "$CANONICAL_ID" \
    "ARCHIVE_FILE" \
    "tar.gz" \
    "${DU_RUST_INSTALL_DIR:-$INSTALL_DIR/rust}" \
    "dust" \
    "dust" \
    -- \
    "--strip-components=1"
