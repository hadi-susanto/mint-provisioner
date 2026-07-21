#!/usr/bin/env bash
set -euo pipefail

source "${LIB_DIR}/common.sh"
source "${LIB_DIR}/installer_apt.sh"
source "${LIB_DIR}/distro.sh"

if ! command -v rsync >/dev/null 2>&1; then
    log_error \
        "[$CANONICAL_ID] rsync is required to migrate /var/lib/docker, but it is not installed"

    exit 1
fi

install_asc_key \
    "$CANONICAL_ID" \
    "https://download.docker.com/linux/ubuntu/gpg" \
    "https://download.docker.com/linux/ubuntu" \
    "$(get_ubuntu_codename)" \
    "stable"
