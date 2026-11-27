#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/messages.sh"
source "$LIB_WORKFLOW/stateful-deb-install.sh"

# The package declares its runtime libraries (GTK 4, WebKitGTK 6.0) and ships the desktop entry and icon.
stateful_deb_install "$CANONICAL_ID" "DEB_FILE" || exit $?

add_message "$CANONICAL_ID" "info" \
    "To use mergediff as the Git mergetool and difftool, see https://github.com/hadi-susanto/mergediff#git-configuration"
