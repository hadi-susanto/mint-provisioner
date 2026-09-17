#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/jetbrains-pre-install.sh"

main "$CANONICAL_ID" "PS" "PhpStorm" "${PHPSTORM_INSTALL_DIR:-${INSTALL_DIR}/phpstorm}" "PHPSTORM_INSTALL_DIR"
