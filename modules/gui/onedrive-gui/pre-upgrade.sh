#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/github.sh"
source "$LIB_INSTALLER/state.sh"

version="$(github_latest_release_version "$CANONICAL_ID" "bpozdena" "OneDriveGUI")" || exit $?
tlog_info "pre-upgrade:$CANONICAL_ID" "Latest OneDriveGUI release: %s" "$version"
set_state "VERSION" "$version" || exit $?
save_states "$CANONICAL_ID" || exit $?
