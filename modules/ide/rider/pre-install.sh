#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/jetbrains-pre-install.sh"

main "$CANONICAL_ID" "RD" "Rider" "${RIDER_INSTALL_DIR:-${INSTALL_DIR}/rider}" "RIDER_INSTALL_DIR"
