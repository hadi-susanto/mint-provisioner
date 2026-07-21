#!/usr/bin/env bash
set -euo pipefail

source "${LIB_DIR}/common.sh"

INSTALL_BASE_DIR="${POWERLEVEL10K_INSTALL_DIR:-$INSTALL_DIR/power-level-10k}"

[[ -d "$INSTALL_BASE_DIR" ]]
