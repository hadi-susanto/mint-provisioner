#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/github.sh"
source "$LIB_WORKFLOW/install-target.sh"
source "$LIB_WORKFLOW/stateful-downloader.sh"

regex="mkcert-.*-linux-amd64$"
install_dir="${MKCERT_INSTALL_DIR:-$INSTALL_DIR/mkcert}"

valid_install_target "$CANONICAL_ID" "$install_dir" "MKCERT_INSTALL_DIR" || exit $?
url="$(github_find_release "$CANONICAL_ID" "FiloSottile" "mkcert" "$regex")" || exit $?
stateful_download "$CANONICAL_ID" "BINARY_FILE" "$url" ""
