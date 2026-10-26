#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_STATEFUL_DEB_UPGRADE_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_STATEFUL_DEB_UPGRADE_LOADED=1

source "$LIB_INSTALLER/apt.sh"
source "$LIB_INSTALLER/state.sh"
source "$LIB_WORKFLOW/version-registry.sh"

##
# stateful_deb_upgrade <canonical_id> <state_name>
#
# Loads module state, resolves a `.deb` path from a state key, and upgrades the
# installed package from it. A package that is no longer installed is not
# installed again (--only-upgrade).
#
# Parameters:
#   canonical_id - Canonical module ID used for state loading and logging.
#   state_name - State key containing the `.deb` file path.
#
# Return:
#   1 - State lookup failed, file/path checks failed, or the upgrade failed.
#
stateful_deb_upgrade() {
    local canonical_id="$1"
    local state_name="$2"
    local tag="upgrade:$canonical_id"
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

    if ! apt_upgrade "$canonical_id" "$deb_file"; then
        tlog_error "$tag" "Failed to upgrade deb package from state key: %s" "$state_name"

        return 1
    fi

    record_version_registry "$canonical_id"
    tlog_info "$tag" "Successfully upgraded from DEB file"

    return 0
}
