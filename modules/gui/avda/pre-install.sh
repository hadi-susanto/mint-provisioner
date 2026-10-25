#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/github.sh"
source "$LIB_WORKFLOW/install-target.sh"
source "$LIB_WORKFLOW/stateful-downloader.sh"

install_dir="${AVDA_INSTALL_DIR:-$INSTALL_DIR/avda}"
regex="avda_linux\\.zip"

valid_install_target "$CANONICAL_ID" "$install_dir" "AVDA_INSTALL_DIR" || exit $?

declare -A asset=()
github_find_release_asset "$CANONICAL_ID" "Sammy-T" "avda" "$regex" asset || exit $?
tag="${asset[URL]#*/releases/download/}"
tag="${tag%%/*}"

stateful_download "$CANONICAL_ID" "ARCHIVE_FILE" "${asset[URL]}" ".zip" 1 "${asset[SHA256]}" "${asset[VERSION]}"
stateful_download "$CANONICAL_ID" "ICON_FILE" \
    "https://raw.githubusercontent.com/Sammy-T/avda/${tag}/build/appicon.png" ".png"
