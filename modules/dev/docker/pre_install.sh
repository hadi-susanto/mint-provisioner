#!/usr/bin/env bash
set -euo pipefail

source "$LIB_COMMON/common.sh"
source "$LIB_INSTALLER/apt.sh"
source "$LIB_INSTALLER/distro.sh"
source "$LIB_INSTALLER/install-target.sh"
source "$LIB_INSTALLER/state.sh"

if ! load_states "$CANONICAL_ID"; then
    tlog_error "pre-install:$CANONICAL_ID" \
        "Docker installation state was not found"

    exit 1
fi

docker_install_dir="$(get_state "DOCKER_LIB_INSTALL_DIR")" || exit 1
docker_install_dir="$(
    resolve_install_target "$CANONICAL_ID" "$docker_install_dir"
)" || exit $?

if ! command -v rsync >/dev/null 2>&1; then
    tlog_error "pre-install:$CANONICAL_ID" \
        "rsync is required to migrate /var/lib/docker, but it is not installed"

    exit 1
fi

if ! ubuntu_codename="$(get_ubuntu_codename)"; then
    tlog_error "pre-install:$CANONICAL_ID" \
        "Failed to determine the upstream Ubuntu codename"

    exit 2
fi

install_asc_key \
    "$CANONICAL_ID" \
    "https://download.docker.com/linux/ubuntu/gpg" \
    "https://download.docker.com/linux/ubuntu" \
    "$ubuntu_codename" \
    "stable"
