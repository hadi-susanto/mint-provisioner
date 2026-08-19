#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/messages.sh"
source "$LIB_WORKFLOW/stateful-deb-install.sh"

stateful_deb_install "$CANONICAL_ID" "DEB_FILE" || exit $?
add_system_toolkit_message "$CANONICAL_ID"
