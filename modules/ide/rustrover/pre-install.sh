#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/jetbrains-pre-install.sh"

main "$CANONICAL_ID" "RR" "RustRover" "${RUSTROVER_INSTALL_DIR:-${INSTALL_DIR}/rustrover}" "RUSTROVER_INSTALL_DIR"
