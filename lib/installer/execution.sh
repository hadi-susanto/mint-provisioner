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
    cleanup
)

##
# exec_interactive
#
# Runs a module's optional interactive setup.
#
# Parameters:
#   canonical_id - Resolved canonical module ID.
#   non_interactive - 1 to disable prompts or 0 to allow them.
#
# Return:
#   0 - The interactive script completed or no script exists.
#   1 - An argument or the interactive-script path is invalid.
#   Other - The interactive script's non-zero status is preserved.
#
exec_interactive() {
    local canonical_id="${1:-}"
    local non_interactive="${2:-}"
    local tag="interactive"

    if [[ -n "$canonical_id" ]]; then
        tag+=":$canonical_id"
    fi

    if (( $# != 2 )) || [[ -z "$canonical_id" ]] ||
        [[ "$non_interactive" != "0" && "$non_interactive" != "1" ]]; then
        tlog_error "$tag" \
            "A canonical ID and non-interactive value of 0 or 1 are required"

        return 1
    fi

    local interactive_script="$MP_MODULES/$canonical_id/interactive.sh"
    local non_interactive_value="false"
    local status

    if (( non_interactive )); then
        non_interactive_value="true"
    fi

    if [[ ! -e "$interactive_script" ]]; then
        return 0
    fi

    if [[ -L "$interactive_script" ]]; then
        tlog_error "$tag" "Interactive script must not be a symbolic link: %s" "$interactive_script"

        return 1
    fi

    if [[ ! -f "$interactive_script" ]]; then
        tlog_error "$tag" "Invalid interactive script: %s" "$interactive_script"

        return 1
    fi

    tlog_info "$tag" "Running interactive setup"

    if run_script \
        "$interactive_script" \
        "CANONICAL_ID" "$canonical_id" \
        "NON_INTERACTIVE" "$non_interactive_value"; then
        return 0
    else
        status=$?
    fi

    tlog_error "$tag" "Interactive setup failed (status: %d)" "$status"

    return "$status"
}

##
# exec_install
#
# Reports mocked installation phases without executing their scripts.
#
# Parameters:
#   canonical_id - Resolved canonical module ID.
#
# Return:
#   0 - Every available installation phase was reported successfully.
#   1 - Input or a phase path is invalid, or install.sh is missing.
#
exec_install() {
    local canonical_id="${1:-}"
    local tag="install"

    if [[ -n "$canonical_id" ]]; then
        tag+=":$canonical_id"
    fi

    if (( $# != 1 )) || [[ -z "$canonical_id" ]]; then
        tlog_error "$tag" "A canonical ID is required"

        return 1
    fi

    local module_dir="$MP_MODULES/$canonical_id"
    local install_script="$module_dir/install.sh"
    local phase
    local phase_script

    # Validate the required installation phase before executing anything.
    if [[ -L "$install_script" ]] || [[ ! -f "$install_script" ]]; then
        tlog_error "$tag" "Required installation phase is missing or invalid: %s" \
            "$install_script"

        return 1
    fi

    # Validate every optional phase before executing anything.
    for phase in "${__EXECUTION_INSTALL_PHASES[@]}"; do
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

        tlog_info "$tag" "Running phase: %s (mocked)" "$phase"
    done

    tlog_info "$tag" "Mock installation completed successfully"

    return 0
}
