#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/jetbrains-interactive.sh"

main "$CANONICAL_ID" \
    "${CLION_NON_INTERACTIVE:-${JETBRAINS_NON_INTERACTIVE:-${NON_INTERACTIVE:-false}}}" \
    "${JETBRAINS_AUTO_INSTALL_JQ:-}" \
    "${JETBRAINS_AUTO_INSTALL_ARIA2:-}"
