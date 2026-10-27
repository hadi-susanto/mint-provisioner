#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/latest-version.sh"
source "$LIB_WORKFLOW/stateful-downloader.sh"

version="$(module_latest_version "$CANONICAL_ID")" || exit $?
url="https://sourceforge.net/projects/deadbeef/files/Builds/${version%-*}/linux/deadbeef-static_${version}_x86_64.tar.bz2/download"

stateful_download "$CANONICAL_ID" "ARCHIVE_FILE" "$url" ".tar.bz2" 1 "" "$version"
