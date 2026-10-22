#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/apt.sh"

install_asc_key \
    "$CANONICAL_ID" \
    "https://dl.k6.io/key.gpg" \
    "https://dl.k6.io/deb" \
    "stable" \
    "main"
