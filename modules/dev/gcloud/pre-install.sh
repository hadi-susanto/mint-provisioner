#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/apt.sh"

install_asc_key \
    "$CANONICAL_ID" \
    "https://packages.cloud.google.com/apt/doc/apt-key.gpg" \
    "https://packages.cloud.google.com/apt" \
    "cloud-sdk" \
    "main"
