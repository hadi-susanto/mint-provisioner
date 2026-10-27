#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/registry.sh"
source "$LIB_WORKFLOW/git-pull-upgrade.sh"

tag="upgrade:$CANONICAL_ID"

if ! load_registry "$CANONICAL_ID" || ! install_path="$(get_registry "INSTALL_PATH")"; then
    tlog_error "$tag" "Installation path is not recorded in the registry"

    exit 1
fi

git_pull_upgrade "$CANONICAL_ID" || exit $?

# The checkout restores the file modes from the repository; the installed
# symlinks point at these files, so keep them executable.
for file in "$install_path"/syskit-*; do
    [[ -f "$file" && ! -L "$file" ]] || continue

    if ! chmod +x "$file"; then
        tlog_error "$tag" "Failed to set executable bit for: %s" "$file"

        exit 1
    fi
done
