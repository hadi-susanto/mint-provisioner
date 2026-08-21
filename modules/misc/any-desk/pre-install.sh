#!/usr/bin/env bash
set -euo pipefail

source "${LIB_COMMON}/common.sh"
source "${LIB_INSTALLER}/apt.sh"

install_asc_key \
    "$CANONICAL_ID" \
    "https://keys.anydesk.com/repos/DEB-GPG-KEY" \
    "http://deb.anydesk.com/" \
    "all" \
    "main"
