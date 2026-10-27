#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/registry.sh"
source "$LIB_INSTALLER/state.sh"
source "$LIB_WORKFLOW/version-registry.sh"

tag="upgrade:$CANONICAL_ID"

if ! load_states "$CANONICAL_ID" || ! binary_file="$(get_state "BINARY_FILE")"; then
    tlog_error "$tag" "State key is not set: BINARY_FILE"

    exit 1
fi

if ! load_registry "$CANONICAL_ID" || ! install_path="$(get_registry "INSTALL_PATH")"; then
    tlog_error "$tag" "Installation path is not recorded in the registry"

    exit 1
fi

if ! staging_file="$(mktemp "$install_path/bin/vault.upgrade.XXXXXX")"; then
    tlog_error "$tag" "Failed to create a staging file in: %s" "$install_path/bin"

    exit 1
fi

# The memory-lock capability belongs to the file, so set it before the new
# binary replaces the old one; mv keeps it.
if ! cp -- "$binary_file" "$staging_file" ||
    ! chmod 0755 -- "$staging_file" ||
    ! sudo setcap cap_ipc_lock=+ep "$staging_file" ||
    ! mv -f -- "$staging_file" "$install_path/bin/vault"; then
    tlog_error "$tag" "Failed to replace %s" "$install_path/bin/vault"
    rm -f -- "$staging_file" || true

    exit 1
fi

record_version_registry "$CANONICAL_ID"
tlog_info "$tag" "Upgrade completed successfully"
