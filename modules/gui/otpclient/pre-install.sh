#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/apt.sh"
source "$LIB_INSTALLER/distro.sh"

version="$(get_ubuntu_version)" || exit $?
repository="https://download.opensuse.org/repositories/home:/polslinux:/otpclient/xUbuntu_${version}/"

install_asc_key \
    "$CANONICAL_ID" \
    "${repository}Release.key" \
    "$repository" \
    "/"
