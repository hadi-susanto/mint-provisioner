#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/registry.sh"
source "$LIB_WORKFLOW/stateful-binary-upgrade.sh"
source "$LIB_WORKFLOW/stateful-extractor.sh"

tag="upgrade:$CANONICAL_ID"

if ! load_registry "$CANONICAL_ID" || ! install_path="$(get_registry "INSTALL_PATH")"; then
    tlog_error "$tag" "Installation path is not recorded in the registry"

    exit 1
fi

# Overwrite bundled themes in place so themes added by the user are kept.
stateful_extract "$CANONICAL_ID" "THEMES_FILE" "zip" "$install_path/themes" || exit $?

# Replace the binary last so VERSION is recorded only after everything succeeded.
stateful_binary_upgrade "$CANONICAL_ID" "BINARY_FILE" "oh-my-posh"
