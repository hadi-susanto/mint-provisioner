#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/messages.sh"
source "$LIB_WORKFLOW/stateful-deb-install.sh"

stateful_deb_install "$CANONICAL_ID" "DEB_FILE" || exit $?

message="rclone installed successfully.

Set up a storage provider (find yours in the list on https://rclone.org/):
    rclone config"

add_message "$CANONICAL_ID" "info" "$message"
