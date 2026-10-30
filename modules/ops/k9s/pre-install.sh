#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/github.sh"
source "$LIB_WORKFLOW/install-target.sh"
source "$LIB_WORKFLOW/stateful-downloader.sh"

regex="/k9s_Linux_amd64[.]tar[.]gz$"
install_dir="${K9S_INSTALL_DIR:-$INSTALL_DIR/k9s}"

valid_install_target "$CANONICAL_ID" "$install_dir" "K9S_INSTALL_DIR" || exit $?
declare -A asset=()
github_find_release_asset "$CANONICAL_ID" "derailed" "k9s" "$regex" asset || exit $?
stateful_download "$CANONICAL_ID" "ARCHIVE_FILE" "${asset[URL]}" ".tar.gz" 1 "${asset[SHA256]}" "${asset[VERSION]}"
