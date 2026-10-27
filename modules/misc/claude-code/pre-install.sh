#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/install-target.sh"
source "$LIB_WORKFLOW/misc/claude-code/downloader.sh"

valid_install_target "$CANONICAL_ID" "${CLAUDE_INSTALL_DIR:-$INSTALL_DIR/claude-code}" "CLAUDE_INSTALL_DIR" || exit $?
claude_code_download "$CANONICAL_ID"
