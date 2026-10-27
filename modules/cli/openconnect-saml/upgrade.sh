#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/registry.sh"
source "$LIB_INSTALLER/state.sh"
source "$LIB_WORKFLOW/cli/openconnect-saml/installer.sh"
source "$LIB_WORKFLOW/version-registry.sh"

tag="upgrade:$CANONICAL_ID"

if ! command -v pipx >/dev/null 2>&1; then
    tlog_error "$tag" "pipx is required to upgrade openconnect-saml"

    exit 1
fi

load_states "$CANONICAL_ID" || exit $?
version="$(get_state "VERSION")" || exit $?

# INSTALL_PATH is a pipx home that may hold other venvs, so it is never swapped.
if ! load_registry "$CANONICAL_ID" || ! install_path="$(get_registry "INSTALL_PATH")"; then
    tlog_error "$tag" "Installation path is not recorded in the registry"

    exit 1
fi

openconnect_saml_install_pipx "$CANONICAL_ID" "$install_path" "$version" || exit $?
record_version_registry "$CANONICAL_ID"
