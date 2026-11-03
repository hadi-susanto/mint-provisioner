#!/usr/bin/env bash
set -euo pipefail

source "${LIB_INSTALLER}/apt.sh"

if [[ "${AUDACIOUS_USE_APT_ADD_REPOSITORY:-${USE_APT_ADD_REPOSITORY:-false}}" == "true" ]]; then
    tlog_info "pre-install:$CANONICAL_ID" "Configuring PPA with add-apt-repository"
    add_ppa "$CANONICAL_ID" "ppa:ubuntuhandbook1/apps"
else
    source "${LIB_INSTALLER}/distro.sh"

    tlog_info "pre-install:$CANONICAL_ID" "Configuring PPA with install_asc_key"
    install_asc_key \
        "$CANONICAL_ID" \
        "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xF4E48910A020E77056748B745738AE8480447DDF" \
        "https://ppa.launchpadcontent.net/ubuntuhandbook1/apps/ubuntu" \
        "$(get_ubuntu_codename)" \
        "main"
fi
