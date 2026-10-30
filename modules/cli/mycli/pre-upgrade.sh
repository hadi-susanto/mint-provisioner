#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/state.sh"
source "$LIB_WORKFLOW/latest-version.sh"

version="$(module_latest_version "$CANONICAL_ID")" || exit $?
tlog_info "pre-upgrade:$CANONICAL_ID" "Latest mycli version: %s" "$version"
set_state "VERSION" "$version" || exit $?
save_states "$CANONICAL_ID" || exit $?
