#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/github.sh"
source "$LIB_WORKFLOW/stateful-downloader.sh"

regex="rclone-v.*-linux-amd64[.]deb$"

url="$(github_find_release "$CANONICAL_ID" "rclone" "rclone" "$regex")" || exit $?
stateful_download "$CANONICAL_ID" "DEB_FILE" "$url" ".deb"
