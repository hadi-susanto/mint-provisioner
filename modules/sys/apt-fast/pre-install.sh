#!/usr/bin/env bash
set -euo pipefail

source "${LIB_INSTALLER}/apt.sh"

if [[ "${APT_FAST_USE_APT_ADD_REPOSITORY:-${USE_APT_ADD_REPOSITORY:-false}}" == "true" ]]; then
    tlog_info "pre-install:$CANONICAL_ID" "Configuring PPA with add-apt-repository"
    add_ppa "$CANONICAL_ID" "ppa:apt-fast/stable"
else
    source "${LIB_INSTALLER}/distro.sh"

    tlog_info "pre-install:$CANONICAL_ID" "Configuring PPA with install_asc_key"
    ubuntu_codename="$(get_ubuntu_codename)" || exit $?
    install_asc_key \
        "$CANONICAL_ID" \
        "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xBC5934FD3DEBD4DAEA544F791E2824A7F22B44BD" \
        "https://ppa.launchpadcontent.net/apt-fast/stable/ubuntu" \
        "$ubuntu_codename" \
        "main"
fi
