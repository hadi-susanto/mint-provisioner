#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/stateful-binary-install.sh"

stateful_binary_install \
    "$CANONICAL_ID" \
    "BINARY_FILE" \
    "${KUBECTL_INSTALL_DIR:-$INSTALL_DIR/kubectl}" \
    "kubectl" || exit $?
