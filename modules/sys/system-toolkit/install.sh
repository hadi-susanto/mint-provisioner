#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/symlink.sh"
source "$LIB_WORKFLOW/git-clone-install.sh"

declare -r SYSTEM_TOOLKIT_URL="https://github.com/hadi-susanto/system-toolkit.git"

git_clone_install \
    "$CANONICAL_ID" \
    "$SYSTEM_TOOLKIT_URL" \
    "${SYSTEM_TOOLKIT_INSTALL_DIR:-$INSTALL_DIR/system-toolkit}" \
    "syskit-bash" "syskit-zsh" "syskit-bin" "syskit-cfg" || exit $?

tag="symlink:$CANONICAL_ID"
install_path="$(get_registry "INSTALL_PATH")"
files=("$install_path"/syskit-*)

for file in "${files[@]}"; do
    if [[ ! -f "$file" || -L "$file" ]]; then
        tlog_warn "$tag" "%s is not a regular file" "$file"

        continue
    fi
    if ! chmod +x "$file"; then
        tlog_error "$tag" "Failed to set executable bit for: %s" "$file"

        continue
    fi
    if ! symlink_binary "$CANONICAL_ID" "$file"; then
        tlog_error "$tag" "Failed to symlink %s" "$file"

        continue
    fi
done
