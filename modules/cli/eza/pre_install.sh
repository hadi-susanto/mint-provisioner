#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/apt.sh"

install_asc_key \
    "$CANONICAL_ID" \
    "https://raw.githubusercontent.com/eza-community/eza/main/deb.asc" \
    "http://deb.gierens.de" \
    "stable" \
    "main"
