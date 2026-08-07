#!/usr/bin/env bash
set -euo pipefail

source "${MP_MODULES}/ide/jetbrains_install.sh"

main "$CANONICAL_ID" "${DATAGRIP_INSTALL_DIR:-${INSTALL_DIR}/datagrip}" "DataGrip" "Database;SQL"
