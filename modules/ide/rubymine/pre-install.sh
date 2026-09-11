#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/jetbrains-pre-install.sh"

main "$CANONICAL_ID" "RM" "RubyMine" "${RUBYMINE_INSTALL_DIR:-${INSTALL_DIR}/rubymine}" "RUBYMINE_INSTALL_DIR"
