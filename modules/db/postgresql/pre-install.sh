#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/apt.sh"
source "$LIB_INSTALLER/distro.sh"

ubuntu_codename="$(get_ubuntu_codename)" || exit $?
install_asc_key \
    "$CANONICAL_ID" \
    "https://www.postgresql.org/media/keys/ACCC4CF8.asc" \
    "https://apt.postgresql.org/pub/repos/apt" \
    "${ubuntu_codename}-pgdg" \
    "main"
