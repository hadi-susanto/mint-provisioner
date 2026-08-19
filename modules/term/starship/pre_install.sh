#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/github.sh"
source "$LIB_WORKFLOW/install-target.sh"
source "$LIB_WORKFLOW/stateful-downloader.sh"

regex="starship-x86_64-unknown-linux-musl\\.tar\\.gz$"
install_dir="${STARSHIP_INSTALL_DIR:-$INSTALL_DIR/starship}"

valid_install_target "$CANONICAL_ID" "$install_dir" "$install_dir" || exit $?
url="$(github_find_release "$CANONICAL_ID" "starship" "starship" "$regex")" || exit $?
stateful_download "$CANONICAL_ID" "ARCHIVE_FILE" "$url" ".tar.gz"
