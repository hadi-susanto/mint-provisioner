#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/install-target.sh"
source "$LIB_WORKFLOW/latest-version.sh"
source "$LIB_WORKFLOW/stateful-downloader.sh"

install_dir="${DEADBEEF_INSTALL_DIR:-$INSTALL_DIR/deadbeef}"

valid_install_target "$CANONICAL_ID" "$install_dir" "DEADBEEF_INSTALL_DIR" || exit $?

version="$(module_latest_version "$CANONICAL_ID")" || exit $?
url="https://sourceforge.net/projects/deadbeef/files/Builds/${version%-*}/linux/deadbeef-static_${version}_x86_64.tar.bz2/download"

stateful_download "$CANONICAL_ID" "ARCHIVE_FILE" "$url" ".tar.bz2" 1 "" "$version"
