#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/jetbrains-pre-install.sh"

main "$CANONICAL_ID" "GO" "GoLand" "${GOLAND_INSTALL_DIR:-${INSTALL_DIR}/goland}" "GOLAND_INSTALL_DIR"
