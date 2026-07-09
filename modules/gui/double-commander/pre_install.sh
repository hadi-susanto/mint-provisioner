#!/usr/bin/env bash

source "${LIB_DIR}/installer_apt.sh"
source "${LIB_DIR}/distro.sh"

UBUNTU_VERSION=$(get_ubuntu_version)
install_asc_key \
    "double-commander" \
    "https://download.opensuse.org/repositories/home:Alexx2000/xUbuntu_${UBUNTU_VERSION}/Release.key" \
    "http://download.opensuse.org/repositories/home:/Alexx2000/xUbuntu_${UBUNTU_VERSION}/" \
    "/" \
    ""
