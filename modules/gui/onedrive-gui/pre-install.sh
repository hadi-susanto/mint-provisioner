#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/github.sh"
source "$LIB_INSTALLER/state.sh"
source "$LIB_WORKFLOW/install-target.sh"

if ! command -v python3 >/dev/null 2>&1; then
    tlog_error "pre-install:$CANONICAL_ID" "python3 is required but not installed."

    exit 1
fi

if ! python3 -c 'import sys; raise SystemExit(sys.version_info < (3, 10))'; then
    tlog_error "pre-install:$CANONICAL_ID" "OneDriveGUI requires Python 3.10 or newer."

    exit 1
fi

if ! command -v onedrive >/dev/null 2>&1; then
    tlog_error "pre-install:$CANONICAL_ID" "OneDrive Client is required but not installed. Install it first using: mp install cli/onedrive"

    exit 1
fi

# pip needs git to install OneDriveGUI from its Git source.
if ! command -v git >/dev/null 2>&1; then
    tlog_error "pre-install:$CANONICAL_ID" "git is required but not installed."

    exit 1
fi

install_dir="${PIPX_INSTALL_DIR:-$INSTALL_DIR/pipx}"
valid_install_target "$CANONICAL_ID" "$install_dir" "PIPX_INSTALL_DIR" || exit $?

version="$(github_latest_release_version "$CANONICAL_ID" "bpozdena" "OneDriveGUI")" || exit $?
tlog_info "pre-install:$CANONICAL_ID" "Latest OneDriveGUI release: %s" "$version"
set_state "VERSION" "$version" || exit $?
save_states "$CANONICAL_ID" || exit $?
