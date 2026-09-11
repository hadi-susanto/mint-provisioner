#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/github.sh"
source "$LIB_WORKFLOW/stateful-downloader.sh"

regex="mucommander_.*_x86_64\\.deb"

url="$(github_find_release "$CANONICAL_ID" "mucommander" "mucommander" "$regex")" || exit $?
stateful_download "$CANONICAL_ID" "DEB_FILE" "$url" ".deb"
