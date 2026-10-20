#!/usr/bin/env bash
set -euo pipefail

source "${LIB_INSTALLER}/apt.sh"
source "${LIB_INSTALLER}/distro.sh"
source "${LIB_INSTALLER}/messages.sh"

stale_service_link="/etc/systemd/user/default.target.wants/onedrive.service"

if [[ -e "$stale_service_link" || -L "$stale_service_link" ]]; then
    message="Found a stale user service link from a distro onedrive package:
    $stale_service_link

Upstream recommends removing it to avoid restart loops and notification spam:
    sudo rm $stale_service_link"

    tlog_warn "pre-install:$CANONICAL_ID" "Found stale onedrive user service link: %s" "$stale_service_link"

    if ! add_message "$CANONICAL_ID" "warn" "$message"; then
        tlog_warn "pre-install:$CANONICAL_ID" "Failed to persist the stale service link warning"
    fi
fi

ubuntu_version="$(get_ubuntu_version)" || exit $?
repository="https://download.opensuse.org/repositories/home:/npreining:/debian-ubuntu-onedrive/xUbuntu_${ubuntu_version}/"

install_asc_key \
    "$CANONICAL_ID" \
    "${repository}Release.key" \
    "$repository" \
    "/"
