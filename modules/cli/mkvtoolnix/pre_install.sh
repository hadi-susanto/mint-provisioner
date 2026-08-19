#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/apt.sh"
source "$LIB_INSTALLER/distro.sh"

ubuntu_codename="$(get_ubuntu_codename)" || exit $?
install_asc_key \
    "$CANONICAL_ID" \
    "https://mkvtoolnix.download/gpg-pub-moritzbunkus.gpg" \
    "https://mkvtoolnix.download/ubuntu/" \
    "$ubuntu_codename" \
    "main"
