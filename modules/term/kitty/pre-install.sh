#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/github.sh"
source "$LIB_WORKFLOW/install-target.sh"
source "$LIB_WORKFLOW/stateful-downloader.sh"

regex="x86_64\\.txz$"
install_dir="${KITTY_INSTALL_DIR:-$INSTALL_DIR/adb}"

valid_install_target "$CANONICAL_ID" "$install_dir" "KITTY_INSTALL_DIR" || exit $?
url="$(github_find_release "$CANONICAL_ID" "kovidgoyal" "kitty" "$regex")" || exit $?
stateful_download "$CANONICAL_ID" "ARCHIVE_FILE" "$url" ".txz"
