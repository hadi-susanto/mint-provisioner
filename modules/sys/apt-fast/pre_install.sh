#!/usr/bin/env bash

source "${LIB_DIR}/installer_apt.sh"

if [[ "${APT_FAST_USE_APT_ADD_REPOSITORY:-${USE_APT_ADD_REPOSITORY:-false}}" == "true" ]]; then
    log_info "[$CANONICAL_ID] configuring PPA with add-ppa-repository command"
    add_ppa apt-fast ppa:apt-fast/stable
else
    source "${LIB_DIR}/distro.sh"

    log_info "[$CANONICAL_ID] configuring PPA with install_asc_key command"
    install_asc_key \
        "$CANONICAL_ID" \
        "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xBC5934FD3DEBD4DAEA544F791E2824A7F22B44BD" \
        "https://ppa.launchpadcontent.net/apt-fast/stable/ubuntu" \
        "$(get_ubuntu_codename)" \
        "main"
fi
