#!/usr/bin/env bash
set -euo pipefail

source "${LIB_INSTALLER}/apt.sh"

# FirefoxPWA publishes cross-distribution packages only to the "any" repository.
install_asc_key \
    "$CANONICAL_ID" \
    "https://packagecloud.io/filips/FirefoxPWA/gpgkey" \
    "https://packagecloud.io/filips/FirefoxPWA/any" \
    "any" \
    "main"
