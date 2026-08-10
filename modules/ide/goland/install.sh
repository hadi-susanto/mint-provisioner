#!/usr/bin/env bash
set -euo pipefail

source "${MP_MODULES}/ide/jetbrains_install.sh"

main "$CANONICAL_ID" "${GOLAND_INSTALL_DIR:-${INSTALL_DIR}/goland}" "GoLand" "Go;GoLang"
