#!/usr/bin/env bash
set -euo pipefail

source "${LIB_DIR}/installer_apt.sh"

install_asc_key \
    "$CANONICAL_ID" \
    "https://packages.microsoft.com/keys/microsoft.asc" \
    "https://packages.microsoft.com/repos/code" \
    "stable" \
    "main"
