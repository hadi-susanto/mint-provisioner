#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/github.sh"
source "$LIB_WORKFLOW/stateful-downloader.sh"

regex="HttpToolkit-.*-x64[.]deb$"
tag="pre-install:$CANONICAL_ID"

url="$(github_find_release "$CANONICAL_ID" "httptoolkit" "httptoolkit-desktop" "$regex")" || exit $?
stateful_download "$CANONICAL_ID" "DEB_FILE" "$url" ".deb" || exit $?
