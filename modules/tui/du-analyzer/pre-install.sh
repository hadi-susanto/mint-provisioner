#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/github.sh"
source "$LIB_WORKFLOW/install-target.sh"
source "$LIB_WORKFLOW/stateful-downloader.sh"

regex="dua-.*-x86_64-unknown-linux-musl\.tar\.gz$"
install_dir="${DU_ANALYZER_INSTALL_DIR:-$INSTALL_DIR/du-analyzer}"

valid_install_target "$CANONICAL_ID" "$install_dir" "DU_ANALYZER_INSTALL_DIR" || exit $?
url="$(github_find_release "$CANONICAL_ID" "byron" "dua-cli" "$regex")" || exit $?
stateful_download "$CANONICAL_ID" "ARCHIVE_FILE" "$url" ".tar.gz"
