#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/jetbrains-install.sh"

main "$CANONICAL_ID" "${CLION_INSTALL_DIR:-${INSTALL_DIR}/clion}" "CLion" "C;C++;CMake;Embedded"
