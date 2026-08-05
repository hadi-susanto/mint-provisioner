#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/path.sh"

__add_access_message() {
    local canonical_id="$1"
    local install_path="$2"
    local message

    message="Mint Provisioner cannot install to $install_path as the current user.
Create the target directory or adjust its ownership and permissions, then retry the installation."

    if ! add_message "$canonical_id" info "$message"; then
        tlog_warn "pre-install:$canonical_id" "Failed to persist installation-directory guidance"
    fi
}

main() {
    local canonical_id="$1"
    local install_path="$2"

    if ! command -v git >/dev/null 2>&1; then
        tlog_error "pre-install:$canonical_id" "git is required but not installed"

        return 1
    fi

    if [[ -e "$install_path" && ! -d "$install_path" ]]; then
        tlog_error "pre-install:$canonical_id" \
            "Installation target exists but is not a directory: %s" "$install_path"
        __add_access_message "$canonical_id" "$install_path"

        return 1
    fi

    if ! can_write "$install_path"; then
        tlog_error "pre-install:$canonical_id" \
            "Installation target is not writable by the current user: %s" "$install_path"
        __add_access_message "$canonical_id" "$install_path"

        return 1
    fi
}

main "$CANONICAL_ID" "${POWERLEVEL10K_INSTALL_DIR:-$INSTALL_DIR/power-level-10k}"
