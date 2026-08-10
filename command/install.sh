#!/usr/bin/env bash
set -euo pipefail

source "$LIB_COMMON/common.sh"
source "$LIB_COMMON/metadata.sh"
source "$LIB_COMMON/resolver.sh"
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
    local non_interactive="${1:-}"

    if (( $# < 1 )) ||
        [[ "$non_interactive" != "0" && "$non_interactive" != "1" ]]; then
        log_error "Interactive setup requires a non-interactive value of 0 or 1"

        return 1
    fi

    shift

    local canonical_id
    local status

    for canonical_id in "$@"; do
        if exec_interactive "$canonical_id" "$non_interactive"; then
            continue
        else
            status=$?
        fi

        log_error "Interactive setup failed; installation aborted"

        return "$status"
    done

    return 0
}

__build_unattended_retry_command() {
    local result_name="$1"
    shift

    local -n result_ref="$result_name"
    local argument
    local quoted_argument

    result_ref="sudo -v && mp install"

    for argument in "$@"; do
        printf -v quoted_argument '%q' "$argument"
        result_ref+=" $quoted_argument"
    done
}

__cache_sudo_privileges() {
    local response

    log_info \
        "The installer can cache sudo privileges now so modules can invoke sudo when necessary."

    if ! IFS= read -r -p "Cache sudo privileges now? (Y/n): " response; then
        log_error "Unable to read the sudo privilege response"

        return 1
    fi

    response="${response:-y}"

    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        log_info "Acquiring sudo privileges..."

        if ! sudo -v; then
            log_error "Failed to acquire sudo privileges"

            return 1
        fi

        return 0
    fi

    log_info "Continuing without cached sudo privileges"

    return 0
}

__validate_sudo_privileges() {
    log_info \
        "Non-interactive mode: validating cached or passwordless sudo privileges..."

    if sudo -n -v; then
        return 0
    fi

    __build_unattended_retry_command retry_command "$@"
    log_error \
        "Non-interactive mode could not acquire sudo privileges without prompting"
    log_info "Retry after validating sudo privileges: %s" "$retry_command"

    return 1
}

__current_time_ms() {
    local current_time

    if ! current_time="$(date +%s%3N)" ||
        [[ ! "$current_time" =~ ^[0-9]+$ ]]; then
        log_error "Unable to read the current time in milliseconds"

        return 1
    fi

    printf '%s\n' "$current_time"
}

__format_module_duration() {
    local duration_ms="$1"
    local result_name="$2"
    local -n result_ref="$result_name"

    printf -v result_ref '%d.%03d second(s)' \
        "$((duration_ms / 1000))" "$((duration_ms % 1000))"
}

__format_total_duration() {
    local duration_ms="$1"
    local result_name="$2"
    local -n result_ref="$result_name"
    local total_seconds=$((duration_ms / 1000))

    printf -v result_ref '%02d:%02d.%03d' \
        "$((total_seconds / 60))" \
        "$((total_seconds % 60))" \
        "$((duration_ms % 1000))"
}

__print_module_header() {
    local canonical_id="$1"
    local name="$2"
    local description="${3:-}"

    printf '%s\n' \
        '----------------------------------------------------------------------'
    printf 'Installing: %b%s%b\n' "$COLOR_BLUE" "$name" "$COLOR_RESET"
    printf 'Module ID : %b%s%b\n' "$COLOR_YELLOW" "$canonical_id" "$COLOR_RESET"
    if [[ -n "$description" ]]; then
        printf '%s\n' "$description"
    fi
    printf '%s\n' \
        '----------------------------------------------------------------------'
}

__print_module_footer() {
    local status="$1"
    local duration="$2"
    local status_text
    local status_color

    if [[ "$status" == "SUCCESS" ]]; then
        status_text="Installation succeeded"
        status_color="$COLOR_GREEN"
    else
        status_text="Installation failed"
        status_color="$COLOR_RED"
    fi

    printf '%s\n' \
        '----------------------------------------------------------------------'
    printf -- '-= %b%s%b =- [duration: %b%s%b]\n' \
        "$status_color" "$status_text" "$COLOR_RESET" \
        "$COLOR_YELLOW" "$duration" "$COLOR_RESET"
    printf '%s\n' \
        '----------------------------------------------------------------------'
}

__run_installation() {
    local canonical_id
    local start_time_ms
    local end_time_ms
    local total_start_time_ms
    local total_end_time_ms
    local duration_ms
    local total_duration_ms
    local duration
    local total_duration
    local result
    local result_color
    local exit_status=0
    local index
    local message_status
    local -a canonical_ids=("$@")
    local -a durations=()
    local -a results=()

    if ! delete_all_messages; then
        tlog_error "installation" "Failed to clear messages from a previous installation run"
    fi

    total_start_time_ms="$(__current_time_ms)" || return $?

    for canonical_id in "${canonical_ids[@]}"; do
        __print_module_header \
            "$canonical_id" \
            "${__MODULE_NAMES[$canonical_id]:-$canonical_id}" \
            "${__MODULE_DESCRIPTIONS[$canonical_id]:-}"

        start_time_ms="$(__current_time_ms)" || return $?
        if exec_install "$canonical_id"; then
            result="SUCCESS"
        else
            result="FAILED"
            exit_status=1
        fi

        end_time_ms="$(__current_time_ms)" || return $?
        duration_ms=$((end_time_ms - start_time_ms))
        __format_module_duration "$duration_ms" duration
        __print_module_footer "$result" "$duration"

        results+=("$result")
        durations+=("$duration")

        printf '\n'
    done

    total_end_time_ms="$(__current_time_ms)" || return $?
    total_duration_ms=$((total_end_time_ms - total_start_time_ms))
    __format_total_duration "$total_duration_ms" total_duration

    printf 'Installation Results [time: %s]\n' "$total_duration"
    printf '%s\n' '=================================================='

    for (( index = 0; index < ${#canonical_ids[@]}; index += 1 )); do
        if [[ "${results[$index]}" == "SUCCESS" ]]; then
            result_color="$COLOR_GREEN"
        else
            result_color="$COLOR_RED"
        fi

        canonical_id="${canonical_ids[$index]}"
        printf '%2d. %b%s%b %b[id: %s]%b %b[%s: %s]%b\n' \
            "$((index + 1))" \
            "$COLOR_BLUE" "${__MODULE_NAMES[$canonical_id]:-$canonical_id}" "$COLOR_RESET" \
            "$COLOR_YELLOW" "$canonical_id" "$COLOR_RESET" \
            "$result_color" "${results[$index]}" "${durations[$index]}" "$COLOR_RESET"

        if has_messages "$canonical_id"; then
            if ! print_messages "$canonical_id" 4; then
                tlog_error "installation:$canonical_id" "Failed to print stored messages"
            fi
        else
            message_status=$?

            if (( message_status > 1 )); then
                tlog_error "installation:$canonical_id" "Failed to inspect stored messages"
            fi
        fi
    done

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
        __validate_sudo_privileges "${original_args[@]}"
    else
        __cache_sudo_privileges || return $?
    fi
    __run_installation "${filtered_ids[@]}"
}

main "$@"
