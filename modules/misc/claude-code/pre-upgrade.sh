#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/misc/claude-code/downloader.sh"

claude_code_download "$CANONICAL_ID"
