#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/stateful-extract-install.sh"

stateful_extract_install \
    "$CANONICAL_ID" \
    "ARCHIVE_FILE" \
    "tar.gz" \
    "${DU_ANALYZER_INSTALL_DIR:-$INSTALL_DIR/du-analyzer}" \
    "dua" \
    "dua" \
    -- \
    "--strip-components=1"
