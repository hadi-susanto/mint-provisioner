#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/jetbrains-install.sh"

main "$CANONICAL_ID" "${GOLAND_INSTALL_DIR:-${INSTALL_DIR}/goland}" "GoLand" "Go;GoLang"
