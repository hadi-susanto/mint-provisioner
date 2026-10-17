#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_REMOVER_EXECUTION_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_REMOVER_EXECUTION_LOADED=1

source "$LIB_COMMON/common.sh"
source "$LIB_COMMON/script.sh"
source "$LIB_INSTALLER/registry.sh"

readonly __REMOVER_PHASE="remove"

__registry_retains_data() {
    local canonical_id="$1"

    load_registry "$canonical_id" silent || return 1
    has_registry DATA_RETAINED || return 1

    [[ "$(get_registry DATA_RETAINED)" == "1" ]]
}

##
# exec_remove
#
# Executes a module's remove.sh phase.
#
# The module registry is deleted only when remove.sh succeeds. Without purge,
# a registry marked DATA_RETAINED=1 (see remove_registry_data_dir) is kept so a
# later mp purge can still locate the retained data directory.
#
# Parameters:
#   canonical_id - Resolved canonical module ID.
#   purge - 1 to run remove.sh in purge mode (PURGE=true), 0 otherwise.
#
# Return:
#   1 - Input is invalid or remove.sh is missing or invalid.
#   Other - remove.sh's non-zero status is preserved.
#
exec_remove() {
    local canonical_id="${1:-}"
    local purge="${2:-}"
    local tag="remover:$canonical_id"
    local remove_script="$MP_MODULES/$canonical_id/$__REMOVER_PHASE.sh"
    local purge_value="false"
    local status

    if (( $# != 2 )) || [[ -z "$canonical_id" ]] ||
        [[ "$purge" != "0" && "$purge" != "1" ]]; then
        tlog_error "remover" "A canonical ID and a purge value of 0 or 1 are required"

        return 1
    fi

    if [[ -L "$remove_script" ]] || [[ ! -f "$remove_script" ]]; then
        tlog_error "$tag" "Module does not support removal; missing or invalid: %s" \
            "$remove_script"

        return 1
    fi

    if (( purge )); then
        purge_value="true"
    fi

    tlog_info "$tag" "Running phase: %s" "$__REMOVER_PHASE"
    if run_script "$remove_script" "CANONICAL_ID" "$canonical_id" "PURGE" "$purge_value"; then
        :
    else
        status=$?
        tlog_error "$tag" "Phase failed: %s (status: %d)" "$__REMOVER_PHASE" "$status"

        return "$status"
    fi

    if (( ! purge )) && __registry_retains_data "$canonical_id"; then
        tlog_info "$tag" "Registry kept: data directory retained for mp purge"
    elif ! delete_registry "$canonical_id"; then
        tlog_warn "$tag" "Removal succeeded but the registry could not be deleted"
    fi

    tlog_info "$tag" "Removal completed successfully"

    return 0
}
