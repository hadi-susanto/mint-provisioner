#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/github.sh"
source "$LIB_WORKFLOW/install-target.sh"
source "$LIB_WORKFLOW/stateful-downloader.sh"

regex="gitui-linux-x86_64\.tar\.gz$"
install_dir="${GIT_UI_INSTALL_DIR:-$INSTALL_DIR/git-ui}"

valid_install_target "$CANONICAL_ID" "$install_dir" "GIT_UI_INSTALL_DIR" || exit $?
url="$(github_find_release "$CANONICAL_ID" "gitui-org" "gitui" "$regex")" || exit $?
stateful_download "$CANONICAL_ID" "ARCHIVE_FILE" "$url" ".tar.gz"
