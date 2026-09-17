#!/usr/bin/env bash
set -euo pipefail

source "${LIB_INSTALLER}/apt.sh"
source "${LIB_INSTALLER}/messages.sh"

apt_install "$CANONICAL_ID" "virtualbox-7.2" || exit $?

message="Oracle VirtualBox 7.2 has been installed successfully.

You can optionally download the Oracle VirtualBox Extension Pack from:

https://www.virtualbox.org/wiki/Downloads

Make sure the Extension Pack version matches the installed VirtualBox version."

add_message "$CANONICAL_ID" "info" "$message"
