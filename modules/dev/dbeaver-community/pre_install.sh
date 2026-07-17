#!/usr/bin/env bash

source "${LIB_DIR}/installer_apt.sh"

if [[ "${DBEAVER_COMMUNITY_USE_APT_ADD_REPOSITORY:-${USE_APT_ADD_REPOSITORY:-false}}" == "true" ]]; then
    log_info "[$CANONICAL_ID] configuring PPA with add-ppa-repository command"
    add_ppa "$CANONICAL_ID" "ppa:serge-rider/dbeaver-ce"
else
    source "${LIB_DIR}/distro.sh"

    log_info "[$CANONICAL_ID] configuring PPA with install_asc_key command"
    install_asc_key \
        "$CANONICAL_ID" \
        "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x30ECE32520D438C21E16BF884A71B51882788FD2" \
        "https://ppa.launchpadcontent.net/serge-rider/dbeaver-ce/ubuntu" \
        "$(get_ubuntu_codename)" \
        "main"
fi
