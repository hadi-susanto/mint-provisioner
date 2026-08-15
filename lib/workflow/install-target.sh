#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_INSTALL_TARGET_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_INSTALL_TARGET_LOADED=1

source "$LIB_INSTALLER/messages.sh"
source "$LIB_INSTALLER/path.sh"

##
# valid_install_target <canonical_id> <raw_path> <env_name>
#
# Validates whether a configured installation target can be used without
# creating or modifying it.
#
# Parameters:
#   canonical_id - Canonical module ID used for logging.
#   raw_path     - Configured installation path to normalize and validate.
#   env_name     - Environment variable name that overrides INSTALL_DIR and is
#                  included in error guidance.
#
# Return:
#   0 - when the target exists as a directory and is writable by the current user.
#   1 - when the path cannot be expanded, the target exists but is not a
#       directory, or the target is not writable by the current user.
#
valid_install_target() {
    local canonical_id="$1"
    local raw_path="$2"
    local env_name="$3"
    local tag="install-target:$canonical_id"
    local install_path
    local message

    install_path="$(expand_path "$raw_path")" || return $?
    if [[ -e "$install_path" ]]; then
        if [[ ! -d "$install_path" ]]; then
            tlog_error "$tag" "Installation target exists but is not a directory: %s" \
                "$install_path"

            message="Mint Provisioner cannot install to: %s
    Target exists but is not a directory.
    Check INSTALL_DIR (default target; module name is appended)
    or $env_name (takes priority over INSTALL_DIR)."
            add_message "$canonical_id" "error" "$message" || true

            return 1
        fi
    fi

    if can_write "$install_path"; then
        return 0
    fi

    tlog_error "$tag" "Installation target is not writable by the current user: %s" \
        "$install_path"

    message="Mint Provisioner cannot install to: /some/path
Target is not writable by the current user.
Check INSTALL_DIR (default target; module name is appended)
or $env_name (takes priority over INSTALL_DIR)."
    add_message "$canonical_id" "error" "$message" || true

    return 1
}
