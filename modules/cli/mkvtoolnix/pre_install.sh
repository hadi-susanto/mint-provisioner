#!/usr/bin/env bash
set -euo pipefail

source "${LIB_DIR}/installer_apt.sh"
source "${LIB_DIR}/distro.sh"

install_asc_key \
    "$CANONICAL_ID" \
    "https://mkvtoolnix.download/gpg-pub-moritzbunkus.gpg" \
    "https://mkvtoolnix.download/ubuntu/" \
    "$(get_ubuntu_codename)" \
    "main"
