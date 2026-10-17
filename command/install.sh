#!/usr/bin/env bash
set -euo pipefail

source "$LIB_COMMON/common.sh"
source "$LIB_COMMON/metadata.sh"
source "$LIB_COMMON/resolver.sh"
source "$LIB_COMMON/run-report.sh"
source "$LIB_COMMON/sudo.sh"
source "$LIB_INSTALLER/detection.sh"
source "$LIB_INSTALLER/execution.sh"
source "$LIB_INSTALLER/messages.sh"

declare -A __MODULE_NAMES=()
declare -A __MODULE_DESCRIPTIONS=()

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
# __filter_installed_modules <force> <result_array> <canonical_id...>
#
# Filters resolved module IDs using one metadata parse and detection call per
# unique canonical ID. Selector order and duplicates are preserved.
#
# Returns:
#   1 after inspecting every unique module when metadata or detection fails.
#   2 when the filter arguments are invalid.
#
__filter_installed_modules() {
    local force="${1:-}"
    local result_name="${2:-}"

    if (( $# < 2 )) || [[ "$force" != "0" && "$force" != "1" ]] ||
        [[ ! "$result_name" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
        log_error \
            "Module filtering requires a force value of 0 or 1 and a result array"

        return 2
    fi

    shift 2

    local -n result_ref="$result_name"
    local -A metadata=()
    local canonical_id
    local module_name
    local failed=0
    local status
    local -a queued=()
    local -a installed=()
    local joined

    result_ref=()
    __MODULE_NAMES=()
    __MODULE_DESCRIPTIONS=()

    tlog_info "installation" "Verifying module installation status..."
    for canonical_id in "$@"; do
        metadata=()

        if ! parse_module_metadata "$MP_MODULES/$canonical_id" metadata; then
            tlog_error "installation:$canonical_id" \
                "Unable to load module metadata: %s" "$canonical_id"
            failed=1

            continue
        fi

        module_name="${metadata[NAME]}"
        __MODULE_NAMES["$canonical_id"]="$module_name"
        __MODULE_DESCRIPTIONS["$canonical_id"]="${metadata[DESCRIPTION]}"

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
            result_ref+=("$canonical_id")
            queued+=("$module_name")

            continue
        fi

        installed+=("$module_name")
        if (( force )); then
            result_ref+=("$canonical_id")
        fi
    done

    if (( failed )); then
        tlog_error "installation" \
            "Installation was aborted. Please review the logs above for more details."

        return "$failed"
    fi

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
            "${__MODULE_NAMES[$canonical_id]:-$canonical_id}" \
            "${__MODULE_DESCRIPTIONS[$canonical_id]:-}"

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
        __MODULE_NAMES canonical_ids results durations

    if ! delete_all_messages; then
        tlog_error "installation" "Failed to delete stored installation messages"
    fi

    return "$exit_status"
}

main() {
    local -A options=()
    local -a args=()
    local -a canonical_ids=()
    local -a filtered_ids=()
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

    if ! __filter_installed_modules "${options[FORCE]}" filtered_ids "${canonical_ids[@]}"; then
        log_error "Installation aborted because module filtering failed"

        return 1
    fi

    if (( ${#filtered_ids[@]} == 0 )); then
        log_info "No modules require installation."

        return 0
    fi

    __run_interactive_session \
        "${options[NON_INTERACTIVE]}" "${filtered_ids[@]}" || return $?
    if (( ${options[NON_INTERACTIVE]} )); then
        validate_sudo_privileges install "${original_args[@]}"
    else
        cache_sudo_privileges || return $?
    fi
    __run_installation "${filtered_ids[@]}"
}

main "$@"
