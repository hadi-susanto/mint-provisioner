#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_INSTALL_PLAN_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_INSTALL_PLAN_LOADED=1

source "$LIB_COMMON/common.sh"
source "$LIB_COMMON/metadata.sh"
source "$LIB_INSTALLER/detection.sh"
source "$LIB_INSTALLER/execution.sh"

# Result of the latest plan_install_modules call. Callers read these arrays
# and must not modify them.
declare -ga INSTALL_PLAN_QUEUE=()
declare -gA INSTALL_PLAN_ACTIONS=()
declare -gA INSTALL_PLAN_NAMES=()
declare -gA INSTALL_PLAN_DESCRIPTIONS=()
declare -gA INSTALL_PLAN_SOURCES=()

##
# plan_install_modules <force> <canonical_id...>
#
# Decides the installation action for each module using one metadata parse
# and one detection call per unique canonical ID. Only errors are logged.
#
# Resets and fills the INSTALL_PLAN_* arrays:
#   INSTALL_PLAN_QUEUE - IDs to install; selector order and duplicates kept.
#   INSTALL_PLAN_ACTIONS - ID to install (not installed), reinstall
#       (installed and force is 1) or skip (installed and force is 0).
#   INSTALL_PLAN_NAMES, INSTALL_PLAN_DESCRIPTIONS, INSTALL_PLAN_SOURCES -
#       ID to module metadata NAME, DESCRIPTION and SOURCE.
#
# Parameters:
#   force - 1 to queue installed modules for reinstallation, 0 otherwise.
#   canonical_id - Resolved canonical module IDs.
#
# Return:
#   1 - Metadata or detection failed for at least one module; every module is
#       still inspected first.
#   2 - The force value is invalid.
#
plan_install_modules() {
    local force="${1:-}"

    if [[ "$force" != "0" && "$force" != "1" ]]; then
        log_error "Module planning requires a force value of 0 or 1"

        return 2
    fi

    shift

    local -A metadata=()
    local -A seen=()
    local canonical_id
    local module_name
    local failed=0
    local status

    INSTALL_PLAN_QUEUE=()
    INSTALL_PLAN_ACTIONS=()
    INSTALL_PLAN_NAMES=()
    INSTALL_PLAN_DESCRIPTIONS=()
    INSTALL_PLAN_SOURCES=()

    for canonical_id in "$@"; do
        if [[ -n "${seen[$canonical_id]:-}" ]]; then
            case "${INSTALL_PLAN_ACTIONS[$canonical_id]:-}" in
                install | reinstall)
                    INSTALL_PLAN_QUEUE+=("$canonical_id")
                    ;;
            esac

            continue
        fi

        seen["$canonical_id"]=1
        metadata=()

        if ! parse_module_metadata "$MP_MODULES/$canonical_id" metadata; then
            tlog_error "installation:$canonical_id" \
                "Unable to load module metadata: %s" "$canonical_id"
            failed=1

            continue
        fi

        module_name="${metadata[NAME]}"
        INSTALL_PLAN_NAMES["$canonical_id"]="$module_name"
        INSTALL_PLAN_DESCRIPTIONS["$canonical_id"]="${metadata[DESCRIPTION]}"
        INSTALL_PLAN_SOURCES["$canonical_id"]="${metadata[SOURCE]:-}"

        if module_installed "$canonical_id" metadata; then
            status=0
        else
            status=$?
        fi

        if (( status > 1 )); then
            tlog_error "installation:$canonical_id" \
                "Installed-state detection failed for %s (status: %d)" \
                "$module_name" "$status"
            failed=1

            continue
        fi

        if (( status != 0 )); then
            INSTALL_PLAN_ACTIONS["$canonical_id"]="install"
        elif (( force )); then
            INSTALL_PLAN_ACTIONS["$canonical_id"]="reinstall"
        else
            INSTALL_PLAN_ACTIONS["$canonical_id"]="skip"

            continue
        fi

        INSTALL_PLAN_QUEUE+=("$canonical_id")
    done

    return "$failed"
}

##
# list_install_phases <canonical_id> <result_name>
#
# Lists the installation phases a module provides, in execution order,
# including cleanup. Interactive phases are not included.
#
# Parameters:
#   canonical_id - Resolved canonical module ID.
#   result_name - Name of the indexed array that receives the phase names.
#
list_install_phases() {
    local canonical_id="$1"
    local -n phases_ref="$2"
    local phase

    phases_ref=()

    for phase in "${__EXECUTION_INSTALL_PHASES[@]}" "$__EXECUTION_CLEANUP_PHASE"; do
        if [[ -e "$MP_MODULES/$canonical_id/$phase.sh" ]]; then
            phases_ref+=("$phase")
        fi
    done
}

##
# module_supports_non_interactive <canonical_id>
#
# Checks whether a module can run under 'mp install --non-interactive'
# without running any module script.
#
# Parameters:
#   canonical_id - Resolved canonical module ID.
#
# Return:
#   1 - The module has an interactive.sh without a non-interactive.sh, or a
#       non-interactive.sh without an interactive.sh.
#
module_supports_non_interactive() {
    local module_dir="$MP_MODULES/$1"

    if [[ -e "$module_dir/interactive.sh" ]]; then
        [[ -e "$module_dir/non-interactive.sh" ]]

        return $?
    fi

    [[ ! -e "$module_dir/non-interactive.sh" ]]
}
