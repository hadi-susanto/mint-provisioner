#!/usr/bin/env bash

source "${LIB_DIR}/installer_apt.sh"

if [[ "${KEEPASS_XC_USE_APT_ADD_REPOSITORY:-${USE_APT_ADD_REPOSITORY:-false}}" == "true" ]]; then
    log_info "[$CANONICAL_ID] configuring PPA with add-ppa-repository command"
    add_ppa "$CANONICAL_ID" "ppa:phoerious/keepassxc"
else
    source "${LIB_DIR}/distro.sh"

    log_info "[$CANONICAL_ID] configuring PPA with install_asc_key command"
    install_asc_key \
        "$CANONICAL_ID" \
        "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xD89C66D0E31FEA2874EBD20561922AB60068FCD6" \
        "https://ppa.launchpadcontent.net/phoerious/keepassxc/ubuntu" \
        "$(get_ubuntu_codename)" \
        "main"
fi
