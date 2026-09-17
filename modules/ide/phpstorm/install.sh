#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/jetbrains-install.sh"

main "$CANONICAL_ID" "${PHPSTORM_INSTALL_DIR:-${INSTALL_DIR}/phpstorm}" "PhpStorm" "PHP;Web"
