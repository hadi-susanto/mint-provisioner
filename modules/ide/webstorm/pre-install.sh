#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/jetbrains-pre-install.sh"

main "$CANONICAL_ID" "WS" "WebStorm" "${WEBSTORM_INSTALL_DIR:-${INSTALL_DIR}/webstorm}" "WEBSTORM_INSTALL_DIR"
