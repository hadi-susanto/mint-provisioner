#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/downloader.sh"
source "$LIB_INSTALLER/state.sh"
source "$LIB_WORKFLOW/install-target.sh"
source "$LIB_WORKFLOW/misc/junie/resolver.sh"
source "$LIB_WORKFLOW/stateful-downloader.sh"

tag="pre-install:$CANONICAL_ID"
install_dir="${JUNIE_INSTALL_DIR:-$INSTALL_DIR/junie}"
declare -A release=()

valid_install_target "$CANONICAL_ID" "$install_dir" "JUNIE_INSTALL_DIR" || exit $?

platform="$(resolve_junie_platform "$CANONICAL_ID")" || exit $?
tlog_info "$tag" "Resolving latest Junie release for %s" "$platform"
resolve_junie_release "$CANONICAL_ID" "$platform" release || exit $?

tlog_info "$tag" "Downloading Junie %s (%s)" "${release[VERSION]}" "$platform"
stateful_download "$CANONICAL_ID" "ARCHIVE_FILE" "${release[URL]}" ".zip" 1 \
    "${release[CHECKSUM]}" "${release[VERSION]}"
