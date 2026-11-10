#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/state.sh"
source "$LIB_WORKFLOW/install-target.sh"
source "$LIB_WORKFLOW/latest-version.sh"

if ! command -v python3 >/dev/null 2>&1; then
    tlog_error "pre-install:$CANONICAL_ID" "python3 is required but not installed."

    exit 1
fi

install_dir="${PIPX_INSTALL_DIR:-$INSTALL_DIR/pipx}"
valid_install_target "$CANONICAL_ID" "$install_dir" "PIPX_INSTALL_DIR" || exit $?

version="$(module_latest_version "$CANONICAL_ID")" || exit $?
tlog_info "pre-install:$CANONICAL_ID" "Latest openconnect-saml version: %s" "$version"
set_state "VERSION" "$version" || exit $?
save_states "$CANONICAL_ID" || exit $?
