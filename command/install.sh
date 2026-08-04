#!/usr/bin/env bash
set -euo pipefail

source "$LIB_COMMON/common.sh"
source "$LIB_COMMON/metadata.sh"
source "$LIB_COMMON/resolver.sh"
source "$LIB_INSTALLER/detection.sh"
source "$LIB_INSTALLER/execution.sh"

__parse_args() {
    local options_name="$1"
    local args_name="$2"
    shift 2

    local -n options_ref="$options_name"
    local -n args_ref="$args_name"

    options_ref=(
        [FORCE]=0
    )
    args_ref=()

    while (( $# > 0 )); do
        case "$1" in
            -f | --force)
                options_ref[FORCE]=1
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

    result_ref=()

    for canonical_id in "$@"; do
        metadata=()

        if ! parse_module_metadata "$MP_MODULES/$canonical_id" metadata; then
            tlog_error "install:$canonical_id" \
                "Unable to load module metadata: %s" "$canonical_id"
            failed=1

            continue
        fi

        module_name="${metadata[NAME]}"

        if module_installed "$canonical_id" metadata; then
            status=0
        else
            status=$?
        fi

        if (( status > 1 )); then
            tlog_error "install:$canonical_id" \
                "Installed-state detection failed for %s (status: %d)" \
                "$module_name" "$status"
            failed=1

            continue
        fi

        if (( status != 0 )); then
            tlog_info "install:$canonical_id" "Module will be processed: %s" "$module_name"
            result_ref+=("$canonical_id")

            continue
        fi

        if (( force )); then
            tlog_warn "install:$canonical_id" \
                "Already installed; forcing installation: %s" "$module_name"
            result_ref+=("$canonical_id")
        else
            tlog_info "install:$canonical_id" "Already installed; skipping: %s" "$module_name"
        fi
    done

    return "$failed"
}

__run_interactive_session() {
    local canonical_id
    local status

    for canonical_id in "$@"; do
        if exec_interactive "$canonical_id"; then
            continue
        else
            status=$?
        fi

        log_error "Interactive setup failed; installation aborted"

        return "$status"
    done

    return 0
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

    printf -v result_ref '%d seconds %03d milliseconds' \
        "$((duration_ms / 1000))" "$((duration_ms % 1000))"
}

__format_total_duration() {
    local duration_ms="$1"
    local result_name="$2"
    local -n result_ref="$result_name"
    local total_seconds=$((duration_ms / 1000))

    printf -v result_ref '%d minutes %02d seconds %03d milliseconds' \
        "$((total_seconds / 60))" \
        "$((total_seconds % 60))" \
        "$((duration_ms % 1000))"
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
    local exit_status=0
    local index
    local -a canonical_ids=("$@")
    local -a durations=()
    local -a results=()

    total_start_time_ms="$(__current_time_ms)" || return $?

    for canonical_id in "${canonical_ids[@]}"; do
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

        results+=("$result")
        durations+=("$duration")
    done

    total_end_time_ms="$(__current_time_ms)" || return $?
    total_duration_ms=$((total_end_time_ms - total_start_time_ms))
    __format_total_duration "$total_duration_ms" total_duration

    printf 'Installation Results [time: %s]\n' "$total_duration"
    printf '%s\n' '===================='

    for (( index = 0; index < ${#canonical_ids[@]}; index += 1 )); do
        printf '%2d. %-30s %-7s [time: %s]\n' \
            "$((index + 1))" \
            "${canonical_ids[$index]}" \
            "${results[$index]}" \
            "${durations[$index]}"
    done

    return "$exit_status"
}

main() {
    local -A options=()
    local -a args=()
    local -a canonical_ids=()
    local -a filtered_ids=()
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

    __run_interactive_session "${filtered_ids[@]}" || return $?
    __cache_sudo_privileges || return $?
    __run_installation "${filtered_ids[@]}"
}

main "$@"
