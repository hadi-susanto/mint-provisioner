#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_UPGRADER_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_UPGRADER_LOADED=1

source "$LIB_COMMON/common.sh"
source "$LIB_INSTALLER/apt.sh"
source "$LIB_UPDATER/apt-versioning.sh"

##
# upgrade_supported
#
# Checks whether mp upgrade can upgrade modules with the given UPDATE_MODE.
#
# Parameters:
#   update_mode - Module metadata UPDATE_MODE value.
#
# Return:
#   0 - The update mode can be upgraded.
#   1 - The update mode is not supported yet.
#
upgrade_supported() {
    local update_mode="$1"

    case "$update_mode" in
        apt)
            return 0
            ;;
    esac

    return 1
}

##
# upgrade_module
#
# Upgrades an installed module according to its UPDATE_MODE.
#
# Parameters:
#   canonical_id - Canonical module ID.
#   metadata_name - Name of the associative array containing module metadata.
#
# Return:
#   1 - The upgrade failed.
#   2 - The UPDATE_MODE is not supported or no installed package was found.
#   Other - The upgrade backend's non-zero status is preserved.
#
upgrade_module() {
    local canonical_id="$1"
    local -n metadata_ref="$2"
    local tag="upgrade:$canonical_id"
    local package

    case "${metadata_ref[UPDATE_MODE]:-}" in
        apt)
            if ! package="$(apt_installed_package "${metadata_ref[UPDATE_PACKAGE]}")"; then
                tlog_error "$tag" "No installed package found for UPDATE_PACKAGE=%s" \
                    "${metadata_ref[UPDATE_PACKAGE]}"

                return 2
            fi

            apt_upgrade "$canonical_id" "$package" || return $?
            ;;
        *)
            # github, external, and git need module pre-upgrade/upgrade phases first.
            tlog_error "$tag" "Upgrade is not supported for UPDATE_MODE=%s yet" \
                "${metadata_ref[UPDATE_MODE]:-}"

            return 2
            ;;
    esac
}
