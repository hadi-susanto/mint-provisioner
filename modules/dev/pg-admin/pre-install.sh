#!/usr/bin/env bash
set -euo pipefail

source "$LIB_COMMON/common.sh"
source "$LIB_INSTALLER/distro.sh"
source "$LIB_INSTALLER/apt.sh"

ubuntu_codename="$(get_ubuntu_codename)" || exit $?
install_asc_key \
    "$CANONICAL_ID" \
    "https://www.pgadmin.org/static/packages_pgadmin_org.pub" \
    "https://ftp.postgresql.org/pub/pgadmin/pgadmin4/apt/$ubuntu_codename" \
    "pgadmin4" \
    "main"
