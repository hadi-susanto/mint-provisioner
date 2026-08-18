#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/jetbrains-pre-install.sh"

main "$CANONICAL_ID" "CL" "CLion" "${CLION_INSTALL_DIR:-${INSTALL_DIR}/clion}" "CLION_INSTALL_DIR"
