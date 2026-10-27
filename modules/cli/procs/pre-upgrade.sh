#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/github.sh"
source "$LIB_WORKFLOW/stateful-downloader.sh"

regex="procs-.*-x86_64-linux[.]zip$"

declare -A asset=()
github_find_release_asset "$CANONICAL_ID" "dalance" "procs" "$regex" asset || exit $?
stateful_download "$CANONICAL_ID" "ARCHIVE_FILE" "${asset[URL]}" ".zip" 1 "${asset[SHA256]}" "${asset[VERSION]}"
