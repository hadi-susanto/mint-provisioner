#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/stateful-extract-install.sh"
source "$LIB_INSTALLER/messages.sh"

stateful_extract_install \
    "$CANONICAL_ID" \
    "ARCHIVE_FILE" \
    "tar" \
    "${DIFFTASTIC_INSTALL_DIR:-$INSTALL_DIR/difftastic}" \
    "difft" \
    "difft" || exit $?

add_system_toolkit_message "$CANONICAL_ID"
