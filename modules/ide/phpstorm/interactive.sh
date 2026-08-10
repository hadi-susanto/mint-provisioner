#!/usr/bin/env bash
set -euo pipefail

source "${MP_MODULES}/ide/jetbrains_interactive.sh"

main "$CANONICAL_ID" \
    "${PHPSTORM_NON_INTERACTIVE:-${JETBRAINS_NON_INTERACTIVE:-${NON_INTERACTIVE:-false}}}" \
    "${JETBRAINS_AUTO_INSTALL_JQ:-}" \
    "${JETBRAINS_AUTO_INSTALL_ARIA2:-}"
