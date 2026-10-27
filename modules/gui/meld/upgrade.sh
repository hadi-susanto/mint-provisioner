#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/registry.sh"
source "$LIB_WORKFLOW/git-pull-upgrade.sh"
source "$LIB_WORKFLOW/gui/meld/installer.sh"

previous_commit=""

if ! load_registry "$CANONICAL_ID" || ! install_path="$(get_registry "INSTALL_PATH")"; then
    tlog_error "upgrade:$CANONICAL_ID" "Installation path is not recorded in the registry"

    exit 1
fi

git_pull_upgrade "$CANONICAL_ID" previous_commit || exit $?

if ! meld_compile_runtime_data "$CANONICAL_ID" "$install_path"; then
    # Go back to the previous sources and rebuild their data so Meld still starts.
    git_restore_commit "$CANONICAL_ID" "$previous_commit" || exit 1
    meld_compile_runtime_data "$CANONICAL_ID" "$install_path" || true

    exit 1
fi
