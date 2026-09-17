#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/jetbrains-install.sh"

main "$CANONICAL_ID" "${WEBSTORM_INSTALL_DIR:-${INSTALL_DIR}/webstorm}" "WebStorm" "JavaScript;TypeScript;Web"
