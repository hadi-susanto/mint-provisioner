#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/install-target.sh"
source "$LIB_WORKFLOW/stateful-downloader.sh"
source "$LIB_WORKFLOW/ide/android-studio/resolver.sh"

install_dir="${ANDROID_STUDIO_INSTALL_DIR:-$INSTALL_DIR/android-studio}"

valid_install_target "$CANONICAL_ID" "$install_dir" "ANDROID_STUDIO_INSTALL_DIR" || exit $?

declare -A release_info=()
android_studio_latest_release "$CANONICAL_ID" release_info || exit $?
stateful_download "$CANONICAL_ID" "ARCHIVE_FILE" "${release_info[URL]}" ".tar.gz" 1 \
    "${release_info[SHA256]}" "${release_info[VERSION]}"
