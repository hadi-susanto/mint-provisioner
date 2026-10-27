#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/stateful-extract-upgrade.sh"

stateful_extract_upgrade \
    "$CANONICAL_ID" \
    "ARCHIVE_FILE" \
    "tar" \
    --keep "conf/settings.xml" \
    --keep "conf/toolchains.xml" \
    --keep "lib/ext" \
    "bin/mvn" \
    -- \
    "--strip-components=1"
