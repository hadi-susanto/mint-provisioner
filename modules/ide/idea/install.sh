#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/jetbrains-install.sh"

main "$CANONICAL_ID" "${IDEA_INSTALL_DIR:-${INSTALL_DIR}/idea}" "IntelliJ IDEA" "Java;Kotlin;JVM;Spring"
