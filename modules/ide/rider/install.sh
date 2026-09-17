#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/jetbrains-install.sh"

main "$CANONICAL_ID" "${RIDER_INSTALL_DIR:-${INSTALL_DIR}/rider}" "Rider" "NET;C#;Unity"
