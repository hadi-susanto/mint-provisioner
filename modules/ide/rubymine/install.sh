#!/usr/bin/env bash
set -euo pipefail

source "${MP_MODULES}/ide/jetbrains_install.sh"

main "$CANONICAL_ID" "${RUBYMINE_INSTALL_DIR:-${INSTALL_DIR}/rubymine}" "RubyMine" "Ruby;Rails"
