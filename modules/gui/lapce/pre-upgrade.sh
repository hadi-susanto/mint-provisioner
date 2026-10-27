#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/gui/lapce/downloader.sh"

lapce_download_assets "$CANONICAL_ID"
