#!/usr/bin/env bash

source "${LIB_DIR}/installer_apt.sh"

# Microsoft Edge uses a distribution-independent repository created before
# May 2025. Its signing key does not depend on the Ubuntu version.
install_asc_key \
    "$CANONICAL_ID" \
    "https://packages.microsoft.com/keys/microsoft.asc" \
    "https://packages.microsoft.com/repos/edge" \
    "stable" \
    "main"
