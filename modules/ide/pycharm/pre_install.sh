#!/usr/bin/env bash
set -euo pipefail

source "${MP_MODULES}/ide/jetbrains_pre_install.sh"

main "$CANONICAL_ID" "PCP" "PyCharm" "${PYCHARM_INSTALL_DIR:-${INSTALL_DIR}/pycharm}"
