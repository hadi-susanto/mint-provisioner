#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/jetbrains-install.sh"

main "$CANONICAL_ID" "${RUSTROVER_INSTALL_DIR:-${INSTALL_DIR}/rustrover}" "RustRover" "Rust;Cargo"
