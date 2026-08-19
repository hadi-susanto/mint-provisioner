#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/apt.sh"

install_asc_key \
    "$CANONICAL_ID" \
    "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x9FA6017ECABE0266" \
    "http://debian.usebruno.com/" \
    "bruno" \
    "stable"
