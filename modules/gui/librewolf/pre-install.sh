#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/apt.sh"

install_asc_key \
    "$CANONICAL_ID" \
    "https://repo.librewolf.net/pubkey.gpg" \
    "https://repo.librewolf.net" \
    "librewolf" \
    "main"
