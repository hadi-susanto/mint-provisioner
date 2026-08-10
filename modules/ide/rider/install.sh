#!/usr/bin/env bash
set -euo pipefail

source "${MP_MODULES}/ide/jetbrains_install.sh"

main "$CANONICAL_ID" "${RIDER_INSTALL_DIR:-${INSTALL_DIR}/rider}" "Rider" "NET;C#;Unity"
