#!/usr/bin/env bash
set -euo pipefail

source "$LIB_COMMON/common.sh"
source "$LIB_INSTALLER/distro.sh"
source "$LIB_INSTALLER/apt.sh"

if ! UBUNTU_CODENAME="$(get_ubuntu_codename)"; then
    tlog_error "pre-install:$CANONICAL_ID" \
        "Failed to determine the upstream Ubuntu codename"

    exit 1
fi

if [[ -z "$UBUNTU_CODENAME" ]]; then
    tlog_error "pre-install:$CANONICAL_ID" "Upstream Ubuntu codename is empty"

    exit 2
fi

REPOSITORY_URL="https://ftp.postgresql.org/pub/pgadmin/pgadmin4/apt/$UBUNTU_CODENAME"

if ! install_asc_key \
    "$CANONICAL_ID" \
    "https://www.pgadmin.org/static/packages_pgadmin_org.pub" \
    "$REPOSITORY_URL" \
    "pgadmin4" \
    "main"
then
    tlog_error "pre-install:$CANONICAL_ID" \
        "Failed to configure the pgAdmin APT repository"

    exit 3
fi
