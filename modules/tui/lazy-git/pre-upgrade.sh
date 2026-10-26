#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/github.sh"
source "$LIB_WORKFLOW/stateful-downloader.sh"

regex="lazygit_.*_linux_x86_64\.tar\.gz$"

declare -A asset=()
github_find_release_asset "$CANONICAL_ID" "jesseduffield" "lazygit" "$regex" asset || exit $?
stateful_download "$CANONICAL_ID" "ARCHIVE_FILE" "${asset[URL]}" ".tar.gz" 1 "${asset[SHA256]}" "${asset[VERSION]}"
