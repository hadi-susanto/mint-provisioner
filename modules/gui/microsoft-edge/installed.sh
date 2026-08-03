#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/detection.sh"

package_installed \
    "$CANONICAL_ID" \
    "microsoft-edge-stable" \
    "microsoft-edge-beta" \
    "microsoft-edge-dev" \
    "microsoft-edge-canary"
