#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/apt.sh"
source "$LIB_INSTALLER/messages.sh"

apt_install "$CANONICAL_ID" tlp tlp-rdw || exit $?
tlog_info "install:$CANONICAL_ID" "Enabling TLP service"

if ! sudo systemctl enable --now tlp.service; then
    tlog_error "install:$CANONICAL_ID" "Failed to enable TLP service"

    exit 1
fi

tlog_info "install:$CANONICAL_ID" "TLP service enabled successfully"

message="TLP installed successfully.

Check whether your laptop battery is supported:
    sudo tlp-stat --battery

Edit the TLP configuration:
    sudo nano /etc/tlp.conf

Install the graphical configuration interface:
    mp install gui/tlp-ui"

add_message "$CANONICAL_ID" "info" "$message"
