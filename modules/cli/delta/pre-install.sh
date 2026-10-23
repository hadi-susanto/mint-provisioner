#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/github.sh"
source "$LIB_WORKFLOW/install-target.sh"
source "$LIB_WORKFLOW/stateful-downloader.sh"

regex="delta-.*-x86_64-unknown-linux-musl[.]tar[.]gz$"
install_dir="${DELTA_INSTALL_DIR:-$INSTALL_DIR/delta}"

valid_install_target "$CANONICAL_ID" "$install_dir" "DELTA_INSTALL_DIR" || exit $?
declare -A asset=()
github_find_release_asset "$CANONICAL_ID" "dandavison" "delta" "$regex" asset || exit $?
stateful_download "$CANONICAL_ID" "ARCHIVE_FILE" "${asset[URL]}" ".tar.gz" 1 "${asset[SHA256]}"
