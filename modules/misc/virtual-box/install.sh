#!/usr/bin/env bash

source "${LIB_DIR}/installer_apt.sh"
source "${LIB_DIR}/messages.sh"

apt_install virtualbox-7.2

message="Oracle VirtualBox 7.2 has been installed successfully.

You can optionally download the Oracle VirtualBox Extension Pack from:

https://www.virtualbox.org/wiki/Downloads

Make sure the Extension Pack version matches the installed VirtualBox version."

add_message "$CANONICAL_ID" "info" "$message"
