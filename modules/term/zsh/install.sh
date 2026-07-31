#!/usr/bin/env bash
set -euo pipefail

source "$LIB_DIR/installer_apt.sh"
source "$LIB_DIR/messages.sh"

apt_install zsh

add_system_toolkit_message "$CANONICAL_ID"
