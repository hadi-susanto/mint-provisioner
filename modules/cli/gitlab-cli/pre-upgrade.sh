#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/gitlab.sh"
source "$LIB_WORKFLOW/stateful-downloader.sh"

regex="glab_.*_linux_amd64[.]deb$"

declare -A asset=()
gitlab_find_release_asset "$CANONICAL_ID" "gitlab-org/cli" "$regex" asset "checksums.txt" || exit $?
stateful_download "$CANONICAL_ID" "DEB_FILE" "${asset[URL]}" ".deb" 1 "${asset[SHA256]}" "${asset[VERSION]}"
