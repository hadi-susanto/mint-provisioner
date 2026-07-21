#!/usr/bin/env bash
set -euo pipefail

source "${LIB_DIR}/installer_apt.sh"

if [[ "${CRYPTOMATOR_USE_APT_ADD_REPOSITORY:-${USE_APT_ADD_REPOSITORY:-false}}" == "true" ]]; then
    log_info "[$CANONICAL_ID] Configuring PPA with add-apt-repository"
    add_ppa "$CANONICAL_ID" "ppa:sebastian-stenzel/cryptomator"
else
    source "${LIB_DIR}/distro.sh"

    log_info "[$CANONICAL_ID] Configuring PPA with install_asc_key"
    install_asc_key \
        "$CANONICAL_ID" \
        "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xCD045438B0D383A4039EA86F892C15CD130FEB9A" \
        "https://ppa.launchpadcontent.net/sebastian-stenzel/cryptomator/ubuntu" \
        "$(get_ubuntu_codename)" \
        "main"
fi
