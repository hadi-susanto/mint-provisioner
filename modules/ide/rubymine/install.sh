#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/jetbrains-install.sh"

main "$CANONICAL_ID" "${RUBYMINE_INSTALL_DIR:-${INSTALL_DIR}/rubymine}" "RubyMine" "Ruby;Rails"
