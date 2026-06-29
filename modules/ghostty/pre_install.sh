#!/usr/bin/env bash

source "$LIB_DIR/installer_apt.sh"

MODULE="ghostty"

if [[ "${GHOSTTY_USE_APT_ADD_REPOSITORY:-${USE_APT_ADD_REPOSITORY:-false}}" == "true" ]]; then
    log_info "[$MODULE] configuring PPA with add-ppa-repository command"
    add_ppa_repository ghostty ppa:mkasberg/ghostty-ubuntu
else
    source "${LIB_DIR}/distro.sh"

    log_info "[$MODULE] configuring PPA with fetch_and_install_asc_key command"
    fetch_and_install_asc_key \
        "$MODULE" \
        "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x0721FDF5FECB88DC6920361657C8EF455CEAE491" \
        "https://ppa.launchpadcontent.net/mkasberg/ghostty-ubuntu/ubuntu" \
        "$(get_ubuntu_codename)" \
        "main"
fi
