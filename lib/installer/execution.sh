#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_EXECUTION_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_EXECUTION_LOADED=1

source "$LIB_COMMON/common.sh"
source "$LIB_COMMON/script.sh"

readonly -a __EXECUTION_INSTALL_PHASES=(
    pre_install
    install
    post_install
)
readonly __EXECUTION_CLEANUP_PHASE="cleanup"

##
# exec_interactive
#
# Runs a module's optional interactive setup.
#
# Parameters:
#   canonical_id - Resolved canonical module ID.
#
# Return:
#   0 - The interactive script completed or no script exists.
#   1 - The interactive-script path is invalid.
#   Other - The interactive script's non-zero status is preserved.
#
exec_interactive() {
    local canonical_id="$1"
    local tag="interactive:$canonical_id"
    local interactive_script="$MP_MODULES/$canonical_id/interactive.sh"
    local status

    if [[ ! -e "$interactive_script" ]]; then
        return 0
    fi

    if [[ -L "$interactive_script" || ! -f "$interactive_script" ]]; then
        tlog_error "$tag" "Interactive script must be a regular file: %s" "$interactive_script"

        return 1
    fi

    tlog_info "$tag" "Running interactive setup"
    if run_script "$interactive_script" "CANONICAL_ID" "$canonical_id"; then
        return 0
    else
        status=$?
    fi

    tlog_error "$tag" "Interactive setup failed (status: %d)" "$status"

    return "$status"
}

##
# exec_non_interactive
#
# Runs a module's optional non-interactive setup.
#
# A non-interactive setup is only valid when the module also provides
# an interactive setup. Modules that only provide a non-interactive
# setup should use pre-install instead.
#
# Parameters:
#   canonical_id - Resolved canonical module ID.
#
# Return:
#   0 - The non-interactive setup completed successfully.
#       Also returned when no setup scripts exist.
#   1 - The module setup is invalid, or the non-interactive script
#       is not a regular file.
#   2 - The module does not support non-interactive setup yet.
#   Other - The non-interactive script's non-zero status is preserved.
#
exec_non_interactive() {
    local canonical_id="$1"
    local tag="non-interactive:$canonical_id"
    local interactive_script="$MP_MODULES/$canonical_id/interactive.sh"
    local non_interactive_script="$MP_MODULES/$canonical_id/non-interactive.sh"
    local status

    # Non interactive session should have an interactive session, otherwise setup is invalid
    # Non interactive only session should be use pre-install
    if [[ ! -e "$interactive_script" ]]; then
        if [[ ! -e "$non_interactive_script" ]]; then
            return 0
        fi

        tlog_error "$tag" "Invalid module; non-interactive session found without a corresponding interactive session"

        return 1
    fi

    # Both interactive and non interactive found, valid module we can proceed with non-interactive one
    if [[ ! -e "$non_interactive_script" ]]; then
        tlog_error "$tag" "Invalid module; non-interactive sessions are not supported yet"

        return 2
    fi

    if [[ -L "$non_interactive_script" || ! -f "$non_interactive_script" ]]; then
        tlog_error "$tag" "Non interactive script must be a regular file: %s" "$non_interactive_script"

        return 1
    fi

    tlog_info "$tag" "Running non interactive setup (user prompt will be disabled...)"
    if run_script "$non_interactive_script" "CANONICAL_ID" "$canonical_id" "NON_INTERACTIVE" "true"; then
        return 0
    else
        status=$?
    fi

    tlog_error "$tag" "Non interactive setup failed (status: %d)" "$status"

    return "$status"
}

##
# exec_install
#
# Executes a module's installation lifecycle in phase order.
#
# Parameters:
#   canonical_id - Resolved canonical module ID.
#
# Return:
#   0 - Every available installation phase completed successfully.
#   1 - Input or a phase path is invalid, or install.sh is missing.
#   Other - The first failed normal phase's status is preserved, or cleanup's
#           status is returned when it is the only failed phase.
#
exec_install() {
    local canonical_id="$1"
    local tag="installer:$canonical_id"
    local module_dir="$MP_MODULES/$canonical_id"
    local install_script="$module_dir/install.sh"
    local cleanup_script="$module_dir/$__EXECUTION_CLEANUP_PHASE.sh"
    local phase
    local phase_script
    local primary_status=0
    local cleanup_status=0

    # Validate the required installation phase before executing anything.
    if [[ -L "$install_script" ]] || [[ ! -f "$install_script" ]]; then
        tlog_error "$tag" "Required installation phase is missing or invalid: %s" \
            "$install_script"

        return 1
    fi

    # Validate every optional phase before executing anything.
    for phase in "${__EXECUTION_INSTALL_PHASES[@]}" "$__EXECUTION_CLEANUP_PHASE"; do
        phase_script="$module_dir/$phase.sh"

        if [[ ! -e "$phase_script" ]] && [[ ! -L "$phase_script" ]]; then
            continue
        fi

        if [[ -L "$phase_script" ]] || [[ ! -f "$phase_script" ]]; then
            tlog_error "$tag" "Invalid installation phase: %s" "$phase_script"

            return 1
        fi
    done

    # All phases are valid at this point, so execution can begin.
    for phase in "${__EXECUTION_INSTALL_PHASES[@]}"; do
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

        tlog_error "$tag" "Phase failed: %s (status: %d)" \
            "$phase" "$primary_status"

        break
    done

    if [[ -e "$cleanup_script" ]]; then
        tlog_info "$tag" "Running phase: %s" "$__EXECUTION_CLEANUP_PHASE"

        if run_script "$cleanup_script" "CANONICAL_ID" "$canonical_id"; then
            :
        else
            cleanup_status=$?
            tlog_error "$tag" "Phase failed: %s (status: %d)" \
                "$__EXECUTION_CLEANUP_PHASE" "$cleanup_status"
        fi
    fi

    if (( primary_status != 0 )); then
        if (( cleanup_status != 0 )); then
            tlog_error "$tag" \
                "Preserving the earlier phase failure status after cleanup failed"
        fi

        return "$primary_status"
    fi

    if (( cleanup_status != 0 )); then
        return "$cleanup_status"
    fi

    tlog_info "$tag" "Installation completed successfully"

    return 0
}
