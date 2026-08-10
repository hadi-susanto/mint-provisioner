#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/apt.sh"
source "$LIB_INSTALLER/distro.sh"

if ! ubuntu_codename="$(get_ubuntu_codename)"; then
    tlog_error "pre-install:$CANONICAL_ID" \
        "Failed to determine the upstream Ubuntu codename"

    exit 1
fi

install_asc_key \
    "$CANONICAL_ID" \
    "https://mkvtoolnix.download/gpg-pub-moritzbunkus.gpg" \
    "https://mkvtoolnix.download/ubuntu/" \
    "$ubuntu_codename" \
    "main"
