#!/usr/bin/env bash

source "${LIB_DIR}/installer_apt.sh"

MODULE="cryptomator"

if [[ "${CRYPTOMATOR_USE_APT_ADD_REPOSITORY:-${USE_APT_ADD_REPOSITORY:-false}}" == "true" ]]; then
    log_info "[$MODULE] configuring PPA with add-ppa-repository command"
    add_ppa "$MODULE" "ppa:sebastian-stenzel/cryptomator"
else
    source "${LIB_DIR}/distro.sh"

    log_info "[$MODULE] configuring PPA with install_asc_key command"
    install_asc_key \
        "$MODULE" \
        "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xCD045438B0D383A4039EA86F892C15CD130FEB9A" \
        "https://ppa.launchpadcontent.net/sebastian-stenzel/cryptomator/ubuntu" \
        "$(get_ubuntu_codename)" \
        "main"
fi
