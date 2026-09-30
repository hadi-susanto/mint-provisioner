#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/apt.sh"
source "$LIB_INSTALLER/distro.sh"

ubuntu_codename="$(get_ubuntu_codename)" || exit $?
install_asc_key \
    "$CANONICAL_ID" \
    "https://pgp.mongodb.com/server-8.0.asc" \
    "https://repo.mongodb.org/apt/ubuntu" \
    "${ubuntu_codename}/mongodb-org/8.0" \
    "multiverse"
