#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_UPGRADE_EXECUTION_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_UPGRADE_EXECUTION_LOADED=1

source "$LIB_COMMON/common.sh"
source "$LIB_COMMON/script.sh"

readonly __UPGRADE_PHASE="upgrade"
readonly -a __UPGRADE_PHASES=(
    pre-upgrade
    upgrade
)
readonly __UPGRADE_CLEANUP_PHASE="cleanup"

##
# module_has_upgrade_phase
#
# Checks whether a module ships the upgrade.sh phase.
#
# Parameters:
#   canonical_id - Resolved canonical module ID.
#
# Return:
#   0 - upgrade.sh exists.
#   1 - upgrade.sh does not exist.
#
module_has_upgrade_phase() {
    local canonical_id="$1"

    [[ -e "$MP_MODULES/$canonical_id/$__UPGRADE_PHASE.sh" ]]
}

##
# exec_upgrade
#
# Executes a module's upgrade lifecycle: pre-upgrade, upgrade, then cleanup,
# which runs even after a failed phase.
#
# Parameters:
#   canonical_id - Resolved canonical module ID.
#
# Return:
#   0 - Every available upgrade phase completed successfully.
#   1 - A phase path is invalid or upgrade.sh is missing.
#   Other - The first failed normal phase's status is preserved, or cleanup's
#           status is returned when it is the only failed phase.
#
exec_upgrade() {
    local canonical_id="$1"
    local tag="upgrader:$canonical_id"
    local module_dir="$MP_MODULES/$canonical_id"
    local upgrade_script="$module_dir/$__UPGRADE_PHASE.sh"
    local cleanup_script="$module_dir/$__UPGRADE_CLEANUP_PHASE.sh"
    local phase
    local phase_script
    local primary_status=0
    local cleanup_status=0

    if [[ -L "$upgrade_script" ]] || [[ ! -f "$upgrade_script" ]]; then
        tlog_error "$tag" "Required upgrade phase is missing or invalid: %s" "$upgrade_script"

        return 1
    fi

    for phase in "${__UPGRADE_PHASES[@]}" "$__UPGRADE_CLEANUP_PHASE"; do
        phase_script="$module_dir/$phase.sh"

        if [[ ! -e "$phase_script" ]] && [[ ! -L "$phase_script" ]]; then
            continue
        fi

        if [[ -L "$phase_script" ]] || [[ ! -f "$phase_script" ]]; then
            tlog_error "$tag" "Invalid upgrade phase: %s" "$phase_script"

            return 1
        fi
    done

    for phase in "${__UPGRADE_PHASES[@]}"; do
        phase_script="$module_dir/$phase.sh"

        if [[ ! -e "$phase_script" ]]; then
            continue
        fi

        tlog_info "$tag" "Running phase: %s" "$phase"

        if run_script "$phase_script" "CANONICAL_ID" "$canonical_id"; then
            continue
        else
            primary_status=$?
        fi

        tlog_error "$tag" "Phase failed: %s (status: %d)" "$phase" "$primary_status"

        break
    done

    if [[ -e "$cleanup_script" ]]; then
        tlog_info "$tag" "Running phase: %s" "$__UPGRADE_CLEANUP_PHASE"

        if run_script "$cleanup_script" "CANONICAL_ID" "$canonical_id"; then
            :
        else
            cleanup_status=$?
            tlog_error "$tag" "Phase failed: %s (status: %d)" \
                "$__UPGRADE_CLEANUP_PHASE" "$cleanup_status"
        fi
    fi

    if (( primary_status != 0 )); then
        if (( cleanup_status != 0 )); then
            tlog_error "$tag" "Preserving the earlier phase failure status after cleanup failed"
        fi

        return "$primary_status"
    fi

    if (( cleanup_status != 0 )); then
        return "$cleanup_status"
    fi

    tlog_info "$tag" "Upgrade completed successfully"

    return 0
}
