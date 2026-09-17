#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/github.sh"
source "$LIB_WORKFLOW/install-target.sh"
source "$LIB_WORKFLOW/stateful-downloader.sh"

regex="duf_.*_linux_x86_64\.tar\.gz$"
install_dir="${DUF_INSTALL_DIR:-$INSTALL_DIR/duf}"

valid_install_target "$CANONICAL_ID" "$install_dir" "DUF_INSTALL_DIR" || exit $?
url="$(github_find_release "$CANONICAL_ID" "muesli" "duf" "$regex")" || exit $?
stateful_download "$CANONICAL_ID" "ARCHIVE_FILE" "$url" ".tar.gz"
