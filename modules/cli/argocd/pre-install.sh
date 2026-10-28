#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/github.sh"
source "$LIB_WORKFLOW/install-target.sh"
source "$LIB_WORKFLOW/stateful-downloader.sh"

regex="/argocd-linux-amd64$"
install_dir="${ARGOCD_INSTALL_DIR:-$INSTALL_DIR/argocd}"

valid_install_target "$CANONICAL_ID" "$install_dir" "ARGOCD_INSTALL_DIR" || exit $?
declare -A asset=()
github_find_release_asset "$CANONICAL_ID" "argoproj" "argo-cd" "$regex" asset || exit $?
stateful_download "$CANONICAL_ID" "BINARY_FILE" "${asset[URL]}" "" 1 "${asset[SHA256]}" "${asset[VERSION]}"
