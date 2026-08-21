#!/usr/bin/env bash
set -euo pipefail

source "$LIB_COMMON/common.sh"
source "$LIB_INSTALLER/apt.sh"
source "$LIB_INSTALLER/distro.sh"

if ! command -v rsync >/dev/null 2>&1; then
    tlog_error "pre-install:$CANONICAL_ID" \
        "rsync is required to migrate /var/lib/docker, but it is not installed"

    exit 1
fi

ubuntu_codename="$(get_ubuntu_codename)" || exit $?
install_asc_key \
    "$CANONICAL_ID" \
    "https://download.docker.com/linux/ubuntu/gpg" \
    "https://download.docker.com/linux/ubuntu" \
    "$ubuntu_codename" \
    "stable"
