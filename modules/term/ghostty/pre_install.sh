#!/usr/bin/env bash

source "$LIB_DIR/installer_apt.sh"

if [[ "${GHOSTTY_USE_APT_ADD_REPOSITORY:-${USE_APT_ADD_REPOSITORY:-false}}" == "true" ]]; then
    log_info "[$CANONICAL_ID] configuring PPA with add-ppa-repository command"
    add_ppa ghostty ppa:mkasberg/ghostty-ubuntu
else
    source "${LIB_DIR}/distro.sh"

    log_info "[$CANONICAL_ID] configuring PPA with install_asc_key command"
    install_asc_key \
        "$CANONICAL_ID" \
        "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x0721FDF5FECB88DC6920361657C8EF455CEAE491" \
        "https://ppa.launchpadcontent.net/mkasberg/ghostty-ubuntu/ubuntu" \
        "$(get_ubuntu_codename)" \
        "main"
fi
