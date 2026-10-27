#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/stateful-extract-upgrade.sh"

stateful_extract_upgrade \
    "$CANONICAL_ID" \
    "ARCHIVE_FILE" \
    "tar.bz2" \
    "deadbeef" \
    -- \
    "--strip-components=1"
