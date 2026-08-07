#!/usr/bin/env bash
set -euo pipefail

source "${MP_MODULES}/ide/jetbrains_install.sh"

main "$CANONICAL_ID" "${WEBSTORM_INSTALL_DIR:-${INSTALL_DIR}/webstorm}" "WebStorm" "JavaScript;TypeScript;Web"
