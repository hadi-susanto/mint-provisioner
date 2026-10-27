#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/github.sh"
source "$LIB_WORKFLOW/stateful-downloader.sh"

regex="mise-.*-linux-x64-musl[.]tar[.]xz$"

declare -A asset=()
github_find_release_asset "$CANONICAL_ID" "jdx" "mise" "$regex" asset || exit $?
stateful_download "$CANONICAL_ID" "ARCHIVE_FILE" "${asset[URL]}" ".tar.gz" 1 "${asset[SHA256]}" "${asset[VERSION]}"
