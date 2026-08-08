#!/usr/bin/env bash
set -euo pipefail

source "${LIB_INSTALLER}/apt.sh"
source "${LIB_INSTALLER}/distro.sh"

UBUNTU_VERSION="$(get_ubuntu_version)" || exit $?
install_asc_key \
    "$CANONICAL_ID" \
    "https://download.opensuse.org/repositories/home:Alexx2000/xUbuntu_${UBUNTU_VERSION}/Release.key" \
    "http://download.opensuse.org/repositories/home:/Alexx2000/xUbuntu_${UBUNTU_VERSION}/" \
    "/"
