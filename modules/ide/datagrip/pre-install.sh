#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/jetbrains-pre-install.sh"

main "$CANONICAL_ID" "DG" "DataGrip" "${DATAGRIP_INSTALL_DIR:-${INSTALL_DIR}/datagrip}" "DATAGRIP_INSTALL_DIR"
