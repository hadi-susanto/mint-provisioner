#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/term/oh-my-posh/downloader.sh"

oh_my_posh_download "$CANONICAL_ID"
