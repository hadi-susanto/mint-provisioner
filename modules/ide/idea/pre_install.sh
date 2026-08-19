#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/jetbrains-pre-install.sh"

main "$CANONICAL_ID" "IIU" "IntelliJ IDEA" "${IDEA_INSTALL_DIR:-${INSTALL_DIR}/idea}" "IDEA_INSTALL_DIR"
