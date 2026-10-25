#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/github.sh"
source "$LIB_WORKFLOW/stateful-downloader.sh"

regex="codium_.*_amd64\.deb$"
tag="pre-install:$CANONICAL_ID"

declare -A asset=()
github_find_release_asset "$CANONICAL_ID" "VSCodium" "vscodium" "$regex" asset || exit $?
stateful_download "$CANONICAL_ID" "DEB_FILE" "${asset[URL]}" ".deb" 1 "${asset[SHA256]}" "${asset[VERSION]}"
