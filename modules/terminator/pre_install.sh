#!/usr/bin/env bash

source "$LIB_DIR/installer_apt.sh"

MODULE="terminator"

if [[ "${TERMINATOR_USE_APT_ADD_REPOSITORY:-${USE_APT_ADD_REPOSITORY:-false}}" == "true" ]]; then
    log_info "[$MODULE] configuring PPA with add-ppa-repository command"
    add_ppa_repository terminator ppa:mattrose/terminator
else
    source "${LIB_DIR}/distro.sh"

    log_info "[$MODULE] configuring PPA with fetch_and_install_asc_key command"
    fetch_and_install_asc_key \
        "$MODULE" \
        "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x64DD261C8598A6BAE2A20BD3BD2FE0A01E3164DB" \
        "https://ppa.launchpadcontent.net/mattrose/terminator/ubuntu" \
        "$(get_ubuntu_codename)" \
        "main"
fi
