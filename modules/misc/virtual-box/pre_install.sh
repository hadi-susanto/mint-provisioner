#!/usr/bin/env bash
set -euo pipefail

source "${LIB_COMMON}/common.sh"
source "${LIB_INSTALLER}/apt.sh"
source "${LIB_INSTALLER}/distro.sh"

install_asc_key \
    "$CANONICAL_ID" \
    "https://www.virtualbox.org/download/oracle_vbox_2016.asc" \
    "https://download.virtualbox.org/virtualbox/debian" \
    "$(get_ubuntu_codename)" \
    "contrib"
