#!/usr/bin/env bash

source "${LIB_DIR}/installer_apt.sh"
source "${LIB_DIR}/distro.sh"

install_asc_key \
    "$CANONICAL_ID" \
    "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xAEEB94E9C5A3B54ECFA4A66AA684470CACCAF35C" \
    "http://apt.insync.io/ubuntu" \
    "$(get_ubuntu_codename)" \
    "non-free contrib"
