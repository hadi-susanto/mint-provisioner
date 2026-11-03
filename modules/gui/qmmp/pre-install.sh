#!/usr/bin/env bash
set -euo pipefail

source "${LIB_INSTALLER}/apt.sh"

if [[ "${QMMP_USE_APT_ADD_REPOSITORY:-${USE_APT_ADD_REPOSITORY:-false}}" == "true" ]]; then
    tlog_info "pre-install:$CANONICAL_ID" "Configuring PPA with add-apt-repository"
    add_ppa "$CANONICAL_ID" "ppa:forkotov02/ppa"
else
    source "${LIB_INSTALLER}/distro.sh"

    tlog_info "pre-install:$CANONICAL_ID" "Configuring PPA with install_asc_key"
    install_asc_key \
        "$CANONICAL_ID" \
        "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xAA9712C1943EEE67F76A681085AAC76E8F3B0210" \
        "https://ppa.launchpadcontent.net/forkotov02/ppa/ubuntu" \
        "$(get_ubuntu_codename)" \
        "main"
fi
