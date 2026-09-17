#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/jetbrains-pre-install.sh"

main "$CANONICAL_ID" "PCP" "PyCharm" "${PYCHARM_INSTALL_DIR:-${INSTALL_DIR}/pycharm}" "PYCHARM_INSTALL_DIR"
