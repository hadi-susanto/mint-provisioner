#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/apt.sh"

install_asc_key \
    "$CANONICAL_ID" \
    "https://codeberg.org/api/packages/GramEditor/debian/repository.key" \
    "https://codeberg.org/api/packages/GramEditor/debian" \
    "gram" \
    "release"
