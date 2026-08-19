#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/stateful-downloader.sh"

stateful_download \
    "$CANONICAL_ID" \
    "DEB_FILE" \
    "https://github.com/dbgate/dbgate/releases/latest/download/dbgate-latest.deb" \
    ".deb"
