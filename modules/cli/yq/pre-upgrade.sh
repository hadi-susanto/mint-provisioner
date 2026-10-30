#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/github.sh"
source "$LIB_WORKFLOW/stateful-downloader.sh"

regex="/yq_linux_amd64$"

declare -A asset=()
github_find_release_asset "$CANONICAL_ID" "mikefarah" "yq" "$regex" asset || exit $?
stateful_download "$CANONICAL_ID" "BINARY_FILE" "${asset[URL]}" "" 1 "${asset[SHA256]}" "${asset[VERSION]}"
