#!/usr/bin/env bash
set -euo pipefail

source "${MP_MODULES}/ide/jetbrains_pre_install.sh"

main "$CANONICAL_ID" "DG" "DataGrip" "${DATAGRIP_INSTALL_DIR:-${INSTALL_DIR}/datagrip}"
