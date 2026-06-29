#!/usr/bin/env bash

source "$LIB_DIR/installer_apt.sh"

MODULE="apt-fast"

if [[ "${APT_FAST_USE_APT_ADD_REPOSITORY:-${USE_APT_ADD_REPOSITORY:-false}}" == "true" ]]; then
    log_info "[$MODULE] configuring PPA with add-ppa-repository command"
    add_ppa_repository apt-fast ppa:apt-fast/stable
else
    source "${LIB_DIR}/distro.sh"

    log_info "[$MODULE] configuring PPA with fetch_and_install_asc_key command"
    fetch_and_install_asc_key \
        "$MODULE" \
        "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xBC5934FD3DEBD4DAEA544F791E2824A7F22B44BD" \
        "https://ppa.launchpadcontent.net/apt-fast/stable/ubuntu" \
        "$(get_ubuntu_codename)" \
        "main"
fi

log_info "Setup apt-fast for non-interactive setups (max-downloads: 16, download-flag: true, apt-manager: apt-get)"

sudo debconf-set-selections <<EOF
apt-fast apt-fast/maxdownloads string 16
apt-fast apt-fast/dlflag boolean true
apt-fast apt-fast/aptmanager string apt-get
EOF
