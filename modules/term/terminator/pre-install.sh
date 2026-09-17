#!/usr/bin/env bash
set -euo pipefail

source "${LIB_INSTALLER}/apt.sh"

if [[ "${TERMINATOR_USE_APT_ADD_REPOSITORY:-${USE_APT_ADD_REPOSITORY:-false}}" == "true" ]]; then
    tlog_info "pre-install:$CANONICAL_ID" "Configuring PPA with add-apt-repository"
    add_ppa "$CANONICAL_ID" "ppa:mattrose/terminator"
else
    source "${LIB_INSTALLER}/distro.sh"

    tlog_info "pre-install:$CANONICAL_ID" "Configuring PPA with install_asc_key"
    ubuntu_codename="$(get_ubuntu_codename)" || exit $?
    install_asc_key \
        "$CANONICAL_ID" \
        "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x64DD261C8598A6BAE2A20BD3BD2FE0A01E3164DB" \
        "https://ppa.launchpadcontent.net/mattrose/terminator/ubuntu" \
        "$ubuntu_codename" \
        "main"
fi
