#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/detection.sh"

package_installed \
    "$CANONICAL_ID" \
    "pgadmin4-desktop" \
    "pgadmin4-web" \
    "pgadmin4"
