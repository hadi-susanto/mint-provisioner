#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_UPGRADER_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_UPGRADER_LOADED=1

source "$LIB_COMMON/common.sh"
source "$LIB_INSTALLER/apt.sh"
source "$LIB_UPDATER/apt-versioning.sh"
source "$LIB_UPDATER/execution.sh"

##
# module_upgradable
#
# Checks whether mp upgrade can upgrade a module. apt-mode modules are always
# upgradable; github-, external-, and git-mode modules need an upgrade.sh phase.
#
# Parameters:
#   canonical_id - Canonical module ID.
#   metadata_name - Name of the associative array containing module metadata.
#
# Return:
#   0 - The module can be upgraded.
#   1 - The module cannot be upgraded yet.
#
module_upgradable() {
    local canonical_id="$1"
    local -n metadata_ref="$2"

    case "${metadata_ref[UPDATE_MODE]:-}" in
        apt)
            return 0
            ;;
        github | external | git)
            module_has_upgrade_phase "$canonical_id" || return 1
            ;;
        *)
            return 1
            ;;
    esac
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
#       For github, external, and git, exec_upgrade's status is preserved.
#   Other - The upgrade backend's non-zero status is preserved.
#
upgrade_module() {
    local canonical_id="$1"
    local -n metadata_ref="$2"
    local tag="upgrade:$canonical_id"
    local -a installed_packages=()

    case "${metadata_ref[UPDATE_MODE]:-}" in
        apt)
            if ! apt_installed_packages "${metadata_ref[UPDATE_PACKAGE]}" installed_packages; then
                tlog_error "$tag" "No installed package found for UPDATE_PACKAGE=%s" \
                    "${metadata_ref[UPDATE_PACKAGE]}"

                return 2
            fi

            # --only-upgrade leaves packages that are already current untouched.
            apt_upgrade "$canonical_id" "${installed_packages[@]}" || return $?
            ;;
        github | external | git)
            exec_upgrade "$canonical_id" || return $?
            ;;
        *)
            tlog_error "$tag" "Upgrade is not supported for UPDATE_MODE=%s yet" \
                "${metadata_ref[UPDATE_MODE]:-}"

            return 2
            ;;
    esac
}
