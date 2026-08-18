#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/jetbrains-install.sh"

main "$CANONICAL_ID" "${DATAGRIP_INSTALL_DIR:-${INSTALL_DIR}/datagrip}" "DataGrip" "Database;SQL"
