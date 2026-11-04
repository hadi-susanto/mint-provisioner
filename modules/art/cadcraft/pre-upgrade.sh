#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/artcraft-download.sh"

artcraft_download_release "$CANONICAL_ID" "cadcraft"
