#!/usr/bin/env bash
set -euo pipefail

source "${LIB_DIR}/installer_apt.sh"

if [[ "${DBEAVER_COMMUNITY_USE_APT_ADD_REPOSITORY:-${USE_APT_ADD_REPOSITORY:-false}}" == "true" ]]; then
    log_info "[$CANONICAL_ID] Configuring PPA with add-apt-repository"
    add_ppa "$CANONICAL_ID" "ppa:serge-rider/dbeaver-ce"
else
    source "${LIB_DIR}/distro.sh"

    log_info "[$CANONICAL_ID] Configuring PPA with install_asc_key"
    install_asc_key \
        "$CANONICAL_ID" \
        "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x30ECE32520D438C21E16BF884A71B51882788FD2" \
        "https://ppa.launchpadcontent.net/serge-rider/dbeaver-ce/ubuntu" \
        "$(get_ubuntu_codename)" \
        "main"
fi
