#!/usr/bin/env bash
set -euo pipefail

source "${MP_MODULES}/ide/jetbrains_install.sh"

main "$CANONICAL_ID" "${IDEA_INSTALL_DIR:-${INSTALL_DIR}/idea}" "IntelliJ IDEA" "Java;Kotlin;JVM;Spring"
