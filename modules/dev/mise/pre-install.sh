#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/github.sh"
source "$LIB_WORKFLOW/install-target.sh"
source "$LIB_WORKFLOW/stateful-downloader.sh"

regex="mise-.*-linux-x64-musl[.]tar[.]xz$"
install_dir="${MISE_INSTALL_DIR:-$INSTALL_DIR/mise}"

valid_install_target "$CANONICAL_ID" "$install_dir" "MISE_INSTALL_DIR" || exit $?
url="$(github_find_release "$CANONICAL_ID" "jdx" "mise" "$regex")" || exit $?
stateful_download "$CANONICAL_ID" "ARCHIVE_FILE" "$url" ".tar.gz"
