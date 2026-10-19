#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/github.sh"
source "$LIB_WORKFLOW/stateful-downloader.sh"

regex="deskotp_.*_amd64\\.deb"

url="$(github_find_release "$CANONICAL_ID" "extricator" "deskOTP" "$regex")" || exit $?
stateful_download "$CANONICAL_ID" "DEB_FILE" "$url" ".deb"
