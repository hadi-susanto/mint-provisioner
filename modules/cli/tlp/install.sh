#!/usr/bin/env bash
set -euo pipefail

source "${LIB_DIR}/installer_apt.sh"
source "${LIB_DIR}/messages.sh"

if ! apt_install tlp tlp-rdw; then
    exit 1
fi

log_info "[$CANONICAL_ID] Enabling TLP service"

if ! sudo systemctl enable --now tlp.service; then
    log_error "[$CANONICAL_ID] Failed to enable TLP service"

    exit 1
fi

log_info "[$CANONICAL_ID] TLP service enabled successfully"

message="TLP installed successfully.

Check whether your laptop battery is supported:
    sudo tlp-stat --battery

Edit the TLP configuration:
    sudo nano /etc/tlp.conf

Install the graphical configuration interface:
    ./install.sh gui/tlp-ui"

add_message "$CANONICAL_ID" "info" "$message"
