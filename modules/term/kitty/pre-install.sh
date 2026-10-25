#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/github.sh"
source "$LIB_WORKFLOW/install-target.sh"
source "$LIB_WORKFLOW/stateful-downloader.sh"

regex="x86_64\\.txz$"
install_dir="${KITTY_INSTALL_DIR:-$INSTALL_DIR/adb}"

valid_install_target "$CANONICAL_ID" "$install_dir" "KITTY_INSTALL_DIR" || exit $?
declare -A asset=()
github_find_release_asset "$CANONICAL_ID" "kovidgoyal" "kitty" "$regex" asset || exit $?
stateful_download "$CANONICAL_ID" "ARCHIVE_FILE" "${asset[URL]}" ".txz" 1 "${asset[SHA256]}" "${asset[VERSION]}"
