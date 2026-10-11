#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_STATEFUL_APT_INSTALL_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_STATEFUL_APT_INSTALL_LOADED=1

source "$LIB_INSTALLER/apt.sh"
source "$LIB_INSTALLER/messages.sh"
source "$LIB_INSTALLER/state.sh"

##
# stateful_apt_install <canonical_id> <package_name>
#
# Installs the APT package stored in the module state.
#
# Parameters:
#   canonical_id  - Canonical module ID whose state is loaded.
#   package_name  - State key holding the package name to install.
#
# Return:
#   1 when the package installation fails.
#   Other when loading the state or reading the key fails.
#
stateful_apt_install() {
    local canonical_id="$1"
    local package_name="$2"
    local tag="apt-install:$canonical_id"
    local package

    load_states "$canonical_id" || return $?
    package="$(get_state "$package_name")" || return $?

    if apt_install "$canonical_id" "$package"; then
        tlog_info "$tag" "Package %s successfully installed" "$package"
        add_message "$canonical_id" "info" "Installation success: $package"

        return 0
    fi

    tlog_error "$tag" "Fail to install: %s" "$package"
    add_message "$canonical_id" "warn" "Installation failed: $package"

    return 1
}
