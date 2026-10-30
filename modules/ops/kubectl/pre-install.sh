#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/install-target.sh"
source "$LIB_WORKFLOW/ops/kubectl/resolver.sh"

valid_install_target "$CANONICAL_ID" "${KUBECTL_INSTALL_DIR:-$INSTALL_DIR/kubectl}" "KUBECTL_INSTALL_DIR" || exit $?
kubectl_download_binary "$CANONICAL_ID"
