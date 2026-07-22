#!/usr/bin/env bash
set -euo pipefail

source "${LIB_DIR}/installer_apt.sh"

if [[ "${GEANY_USE_APT_ADD_REPOSITORY:-${USE_APT_ADD_REPOSITORY:-false}}" == "true" ]]; then
    log_info "[$CANONICAL_ID] Configuring PPA with add-apt-repository"
    add_ppa "$CANONICAL_ID" "ppa:geany-dev/ppa"
else
    source "${LIB_DIR}/distro.sh"

    log_info "[$CANONICAL_ID] Configuring PPA with install_asc_key"
    install_asc_key \
        "$CANONICAL_ID" \
        "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xDE52D7C0594C5BDBF940922B361331969CA95183" \
        "https://ppa.launchpadcontent.net/geany-dev/ppa/ubuntu" \
        "$(get_ubuntu_codename)" \
        "main"
fi
