#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/gui/flameshot/downloader.sh"

flameshot_download_deb "$CANONICAL_ID"
