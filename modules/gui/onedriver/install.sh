#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/apt.sh"
source "$LIB_INSTALLER/messages.sh"

apt_install "$CANONICAL_ID" "onedriver" || exit $?

message="onedriver installed successfully.

Launch the onedriver launcher from the application menu, or run:
    onedriver-launcher

Click '+' in the launcher to mount a OneDrive account and sign in through the browser."

add_message "$CANONICAL_ID" "info" "$message"
