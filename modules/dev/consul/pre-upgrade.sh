#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/hashicorp-download.sh"

hashicorp_download_binary "$CANONICAL_ID" "consul"
