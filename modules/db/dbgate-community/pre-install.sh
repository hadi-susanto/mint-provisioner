#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/github.sh"
source "$LIB_WORKFLOW/stateful-downloader.sh"

declare -A asset=()
github_find_release_asset "$CANONICAL_ID" "dbgate" "dbgate" "/dbgate-latest[.]deb$" asset || exit $?
stateful_download "$CANONICAL_ID" "DEB_FILE" "${asset[URL]}" ".deb" 1 "${asset[SHA256]}" "${asset[VERSION]}"
