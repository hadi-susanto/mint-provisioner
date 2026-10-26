#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/github.sh"
source "$LIB_WORKFLOW/stateful-downloader.sh"

regex="x86_64\\.txz$"

declare -A asset=()
github_find_release_asset "$CANONICAL_ID" "kovidgoyal" "kitty" "$regex" asset || exit $?
stateful_download "$CANONICAL_ID" "ARCHIVE_FILE" "${asset[URL]}" ".txz" 1 "${asset[SHA256]}" "${asset[VERSION]}"
