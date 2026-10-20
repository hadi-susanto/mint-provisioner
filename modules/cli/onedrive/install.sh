#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/apt.sh"
source "$LIB_INSTALLER/messages.sh"

apt_install "$CANONICAL_ID" "onedrive" || exit $?

message="OneDrive Client installed successfully.

Authorize your Microsoft account once by running:
    onedrive

Then keep it syncing in the background with:
    systemctl --user enable --now onedrive

Or manage accounts graphically with: mp install gui/onedrive-gui"

add_message "$CANONICAL_ID" "info" "$message"
