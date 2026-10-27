#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/stateful-extract-upgrade.sh"

stateful_extract_upgrade \
    "$CANONICAL_ID" \
    "JETBRAINS_ARCHIVE_FILE" \
    "tar.gz" \
    "bin/webstorm" \
    -- \
    "--strip-components=1"
