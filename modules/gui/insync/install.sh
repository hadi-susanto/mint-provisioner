#!/usr/bin/env bash

source "${LIB_DIR}/installer_apt.sh"
source "${LIB_DIR}/messages.sh"

apt_install insync

message="Insync has been installed successfully.

Start Insync from the desktop application menu to connect your Google Drive,
OneDrive, or Dropbox account and select the folders you want to synchronize.

Optional file-manager integration packages are also available:
 • Caja: 'insync-caja'
 • Dolphin: 'insync-dolphin'
 • Nautilus: 'insync-nautilus'
 • Nemo: 'insync-nemo'
 • Thunar: 'insync-thunar'"

add_message "$CANONICAL_ID" "info" "$message"
