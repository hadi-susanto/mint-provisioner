#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/github.sh"
source "$LIB_WORKFLOW/install-target.sh"
source "$LIB_WORKFLOW/stateful-downloader.sh"

regex="procs-.*-x86_64-linux[.]zip$"
install_dir="${PROCS_INSTALL_DIR:-$INSTALL_DIR/procs}"

valid_install_target "$CANONICAL_ID" "$install_dir" "PROCS_INSTALL_DIR" || exit $?
declare -A asset=()
github_find_release_asset "$CANONICAL_ID" "dalance" "procs" "$regex" asset || exit $?
stateful_download "$CANONICAL_ID" "ARCHIVE_FILE" "${asset[URL]}" ".zip" 1 "${asset[SHA256]}"
