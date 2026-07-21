#!/usr/bin/env bash
set -euo pipefail

#
# Checks if SDKMAN! is installed.
#

if [[ -z "${SDKMAN_INSTALL_DIR:-}" ]]; then
    SDKMAN_INSTALL_DIR="$INSTALL_DIR/sdkman"
fi

if [[ -f "$SDKMAN_INSTALL_DIR/bin/sdkman-init.sh" ]]; then
    exit 0
fi

exit 1
