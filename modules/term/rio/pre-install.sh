#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/term/rio/downloader.sh"

rio_download_deb "$CANONICAL_ID"
