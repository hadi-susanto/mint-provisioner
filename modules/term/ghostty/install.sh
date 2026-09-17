#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/apt.sh"
source "$LIB_INSTALLER/messages.sh"

apt_install "$CANONICAL_ID" "ghostty" || exit $?
add_system_toolkit_message "$CANONICAL_ID"
