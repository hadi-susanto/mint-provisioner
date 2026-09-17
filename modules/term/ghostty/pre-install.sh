#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/apt.sh"

if [[ "${GHOSTTY_USE_APT_ADD_REPOSITORY:-${USE_APT_ADD_REPOSITORY:-false}}" == "true" ]]; then
    tlog_info "pre-install:$CANONICAL_ID" "Configuring PPA with add-apt-repository"
    add_ppa "$CANONICAL_ID" "ppa:mkasberg/ghostty-ubuntu"
else
    source "${LIB_INSTALLER}/distro.sh"

    tlog_info "pre-install:$CANONICAL_ID" "Configuring PPA with install_asc_key"
    ubuntu_codename="$(get_ubuntu_codename)" || exit $?
    install_asc_key \
        "$CANONICAL_ID" \
        "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x0721FDF5FECB88DC6920361657C8EF455CEAE491" \
        "https://ppa.launchpadcontent.net/mkasberg/ghostty-ubuntu/ubuntu" \
        "$ubuntu_codename" \
        "main"
fi
