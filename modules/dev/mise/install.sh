#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/stateful-extract-install.sh"
source "$LIB_INSTALLER/messages.sh"

stateful_extract_install \
    "$CANONICAL_ID" \
    "ARCHIVE_FILE" \
    "tar" \
    "${MISE_INSTALL_DIR:-$INSTALL_DIR/mise}" \
    "bin/mise" \
    "mise" \
    -- \
    "--strip-components=1" || exit $?

add_system_toolkit_message "$CANONICAL_ID"

msg="Unless System Toolkit is used to enable the shell
integration, please read the instructions at:
  https://mise.jdx.dev/"

add_message "$CANONICAL_ID" "info" "$msg"
