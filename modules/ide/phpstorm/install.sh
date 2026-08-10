#!/usr/bin/env bash
set -euo pipefail

source "${MP_MODULES}/ide/jetbrains_install.sh"

main "$CANONICAL_ID" "${PHPSTORM_INSTALL_DIR:-${INSTALL_DIR}/phpstorm}" "PhpStorp" "PHP;Web"
