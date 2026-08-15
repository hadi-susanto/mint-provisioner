#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_STATEFUL_DEB_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_STATEFUL_DEB_LOADED=1

source "$LIB_INSTALLER/apt.sh"
source "$LIB_INSTALLER/state.sh"

##
# stateful_deb_install <canonical_id> <state_name>
#
# Loads module state, resolves a `.deb` path from a state key, and installs it.
#
# Parameters:
#   canonical_id - Canonical module ID used for state loading and logging.
#   state_name - State key containing the `.deb` file path.
#
# Return:
#   1 - State lookup failed, file/path checks failed, or install failed.
#
stateful_deb_install() {
    local canonical_id="$1"
    local state_name="$2"
    local tag="install:$canonical_id"
    local deb_file

    if ! load_states "$canonical_id"; then
        tlog_error "$tag" "Failed to load state for %s" "$canonical_id"

        return 1
    fi

    if ! deb_file="$(get_state "$state_name")"; then
        tlog_error "$tag" "State key is not set: %s" "$state_name"

        return 1
    fi

    if [[ ! -f "$deb_file" ]]; then
        tlog_error "$tag" "State file does not exist: %s" "$deb_file"

        return 1
    fi

    if [[ "$deb_file" != *.deb ]]; then
        tlog_error "$tag" "State file is not a .deb package: %s" "$deb_file"

        return 1
    fi

    if ! apt_install "$canonical_id" "$deb_file"; then
        tlog_error "$tag" "Failed to install deb package from state key: %s" "$state_name"

        return 1
    fi

    tlog_info "$tag" "Successfully installed from DEB file"

    return 0
}
