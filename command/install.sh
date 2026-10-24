#!/usr/bin/env bash
set -euo pipefail

source "$LIB_COMMON/common.sh"
source "$LIB_COMMON/install-plan.sh"
source "$LIB_COMMON/resolver.sh"
source "$LIB_COMMON/run-report.sh"
source "$LIB_COMMON/sudo.sh"
source "$LIB_INSTALLER/execution.sh"
source "$LIB_INSTALLER/messages.sh"

__parse_args() {
    local options_name="$1"
    local args_name="$2"
    shift 2

    local -n options_ref="$options_name"
    local -n args_ref="$args_name"

    options_ref=(
        [FORCE]=0
        [NON_INTERACTIVE]=0
    )
    args_ref=()

    while (( $# > 0 )); do
        case "$1" in
            -f | --force)
                options_ref[FORCE]=1
                shift
                ;;
            -ni | --non-interactive | --unattended)
                options_ref[NON_INTERACTIVE]=1
                shift
                ;;
            --)
                shift
                args_ref+=("$@")
                break
                ;;
            -*)
                log_error "Unsupported install option: %s" "$1"

                return 2
                ;;
            *)
                args_ref+=("$1")
                shift
                ;;
        esac
    done

    return 0
}

__validate_options() {
    local args_name="$1"
    local -n args_ref="$args_name"

    if (( ${#args_ref[@]} == 0 )); then
        log_error "The install command requires at least one module"

        return 2
    fi

    return 0
}

##
# __log_plan_summary <force> <canonical_id...>
#
# Logs which modules are queued for installation or reinstallation and which
# are skipped because they are already installed.
#
__log_plan_summary() {
    local force="$1"
    shift

    local canonical_id
    local joined
    local -a queued=()
    local -a installed=()

    for canonical_id in "$@"; do
        case "${INSTALL_PLAN_ACTIONS[$canonical_id]:-}" in
            install)
                queued+=("${INSTALL_PLAN_NAMES[$canonical_id]}")
                ;;
            reinstall | skip)
                installed+=("${INSTALL_PLAN_NAMES[$canonical_id]}")
                ;;
        esac
    done

    if (( ${#queued[@]} > 0 )); then
        joined=$(printf '%s, ' "${queued[@]}")
        joined=${joined%, }
        tlog_info "installation" \
            "Queued for installation: %s" "$joined"
    fi

    if (( ${#installed[@]} == 0 )); then
        return 0
    fi

    joined=$(printf '%s, ' "${installed[@]}")
    joined=${joined%, }
    if (( force )); then
        tlog_warn "installation" \
            "Queued for reinstallation: %s" "$joined"
    else
        tlog_info "installation" \
            "Skipped because already installed: %s" "$joined"
    fi

    return 0
}

__run_interactive_session() {
    local non_interactive="$1"

    shift

    local canonical_id
    local status

    for canonical_id in "$@"; do
        status=0
        if (( non_interactive )); then
            exec_non_interactive "$canonical_id" || status=$?
        else
            exec_interactive "$canonical_id" || status=$?
        fi

        if (( status == 0 )); then
            continue
        fi

        log_error "Interactive/Non-Interactive setup failed; installation aborted"
        if (( status == 2 )); then
            add_message "$canonical_id" "error" "Module does not support non-interactive sessions yet"
        fi

        return "$status"
    done

    return 0
}

__run_installation() {
    local canonical_id
    local start_time_ms
    local end_time_ms
    local total_start_time_ms
    local total_end_time_ms
    local duration
    local total_duration
    local result
    local exit_status=0
    local -a canonical_ids=("$@")
    local -a durations=()
    local -a results=()

    if ! delete_all_messages; then
        tlog_error "installation" "Failed to clear messages from a previous installation run"
    fi

    total_start_time_ms="$(current_time_ms)" || return $?

    for canonical_id in "${canonical_ids[@]}"; do
        print_module_header \
            "Installing" \
            "$canonical_id" \
            "${INSTALL_PLAN_NAMES[$canonical_id]:-$canonical_id}" \
            "${INSTALL_PLAN_DESCRIPTIONS[$canonical_id]:-}"

        start_time_ms="$(current_time_ms)" || return $?
        if exec_install "$canonical_id"; then
            result="SUCCESS"
        else
            result="FAILED"
            exit_status=1
        fi

        end_time_ms="$(current_time_ms)" || return $?
        format_module_duration "$((end_time_ms - start_time_ms))" duration
        print_module_footer "$result" "$duration" \
            "Installation succeeded" "Installation failed"

        results+=("$result")
        durations+=("$duration")

        printf '\n'
    done

    total_end_time_ms="$(current_time_ms)" || return $?
    format_total_duration "$((total_end_time_ms - total_start_time_ms))" total_duration

    print_run_results "Installation Results" "$total_duration" \
        INSTALL_PLAN_NAMES canonical_ids results durations

    if ! delete_all_messages; then
        tlog_error "installation" "Failed to delete stored installation messages"
    fi

    return "$exit_status"
}

main() {
    local -A options=()
    local -a args=()
    local -a canonical_ids=()
    local -a original_args=("$@")
    local status=0

    __parse_args options args "$@" || status=$?
    if (( status != 0 )); then
        bash "$MP_COMMAND/help.sh" install >&2

        return "$status"
    fi

    __validate_options args || status=$?
    if (( status != 0 )); then
        bash "$MP_COMMAND/help.sh" install >&2

        return "$status"
    fi

    if (( EUID == 0 )); then
        log_error "Do not run 'mp install' with sudo or as root"
        log_error "Module installers invoke sudo themselves only when necessary"
        log_error \
            "Running as root can select the wrong \$HOME, create root-owned files, damage the current user's home setup, or install and configure software for root"

        return 2
    fi

    if ! resolve_module_selectors canonical_ids "${args[@]}"; then
        log_error "Installation aborted because one or more modules could not be resolved"

        return 2
    fi

    tlog_info "installation" "Verifying module installation status..."
    if ! plan_install_modules "${options[FORCE]}" "${canonical_ids[@]}"; then
        tlog_error "installation" \
            "Installation was aborted. Please review the logs above for more details."
        log_error "Installation aborted because module filtering failed"

        return 1
    fi

    __log_plan_summary "${options[FORCE]}" "${canonical_ids[@]}"

    if (( ${#INSTALL_PLAN_QUEUE[@]} == 0 )); then
        log_info "No modules require installation."

        return 0
    fi

    __run_interactive_session \
        "${options[NON_INTERACTIVE]}" "${INSTALL_PLAN_QUEUE[@]}" || return $?
    if (( ${options[NON_INTERACTIVE]} )); then
        validate_sudo_privileges install "${original_args[@]}"
    else
        cache_sudo_privileges || return $?
    fi
    __run_installation "${INSTALL_PLAN_QUEUE[@]}"
}

main "$@"
