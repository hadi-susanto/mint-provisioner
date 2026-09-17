#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/jetbrains-install.sh"

main "$CANONICAL_ID" "${PYCHARM_INSTALL_DIR:-${INSTALL_DIR}/pycharm}" "PyCharm" "Python;Django;Jupyter"
