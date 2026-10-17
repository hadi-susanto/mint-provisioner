#!/usr/bin/env bash
set -euo pipefail

source "$LIB_COMMON/common.sh"
source "$LIB_COMMON/metadata.sh"
source "$LIB_COMMON/resolver.sh"
source "$LIB_COMMON/run-report.sh"
source "$LIB_COMMON/sudo.sh"
source "$LIB_REMOVER/execution.sh"
source "$LIB_REMOVER/filter.sh"

declare -A __MODULE_NAMES=()

__parse_args() {
    local options_name="$1"
    local args_name="$2"
    shift 2

    local -n options_ref="$options_name"
    local -n args_ref="$args_name"

    options_ref=(
        [FORCE]=0
        [PURGE]=0
    )
    args_ref=()

    while (( $# > 0 )); do
        case "$1" in
            -f | --force)
                options_ref[FORCE]=1
                shift
                ;;
            --purge)
                options_ref[PURGE]=1
                shift
                ;;
            --)
                shift
                args_ref+=("$@")
                break
                ;;
            -*)
                log_error "Unsupported remove option: %s" "$1"

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
    local options_name="$1"
    local args_name="$2"
    local -n options_ref="$options_name"
    local -n args_ref="$args_name"

    # Purge always bypasses the installed-state check.
    if (( options_ref[PURGE] )); then
        options_ref[FORCE]=1
    fi

    if (( ${#args_ref[@]} == 0 )); then
        log_error "The remove command requires at least one module"

        return 2
    fi

    return 0
}

##
# __confirm_purge <canonical_id...>
#
# Shows what a purge will delete and requires the user to type PURGE in an
# interactive terminal before anything is removed.
#
# Returns:
#   1 when no terminal is available, the answer cannot be read, or it does not
#   match.
#
__confirm_purge() {
    local canonical_id
    local answer
    local joined
    local -a names=()

    for canonical_id in "$@"; do
        names+=("${__MODULE_NAMES[$canonical_id]:-$canonical_id}")
    done

    joined=$(printf '%s, ' "${names[@]}")

    printf '\n%b%s%b\n' "$COLOR_RED" \
        "WARNING: mp purge permanently deletes software, settings and data. This cannot be undone." \
        "$COLOR_RESET" >&2
    printf 'User   : %s (home: %s)\n' "${USER:-$(id -un)}" "$HOME" >&2
    printf 'Modules: %s\n' "${joined%, }" >&2
    printf '%s\n' \
        'For every module above this will:' \
        '  - purge its packages, including their configuration files under /etc' \
        '  - remove its APT repositories and signing keys' \
        '  - delete its configuration, cache and data under your home directory' \
        '  - delete service data directories, such as databases under /var/lib' \
        '  - delete installation directories recorded by the provisioner' >&2
    printf '%s\n\n' "Use mp remove instead to keep configuration and data." >&2

    if ! source "$LIB_INSTALLER/prompt.sh"; then
        log_error "Purge aborted: an interactive terminal is required to confirm it"

        return 1
    fi

    if ! answer="$(ask_text "Type PURGE to continue")"; then
        log_error "Purge aborted: the confirmation could not be read"

        return 1
    fi

    if [[ "$answer" != "PURGE" ]]; then
        log_error "Purge aborted: the confirmation text did not match"

        return 1
    fi

    return 0
}

__run_removal() {
    local purge="$1"
    shift

    local canonical_id
    local start_time_ms
    local end_time_ms
    local total_start_time_ms
    local total_end_time_ms
    local duration
    local total_duration
    local result
    local exit_status=0
    local title="Removal"
    local -a canonical_ids=("$@")
    local -a durations=()
    local -a results=()

    if (( purge )); then
        title="Purge"
    fi

    if ! delete_all_messages; then
        tlog_error "removal" "Failed to clear messages from a previous run"
    fi

    total_start_time_ms="$(current_time_ms)" || return $?

    for canonical_id in "${canonical_ids[@]}"; do
        print_module_header \
            "$title" \
            "$canonical_id" \
            "${__MODULE_NAMES[$canonical_id]:-$canonical_id}"

        start_time_ms="$(current_time_ms)" || return $?
        if exec_remove "$canonical_id" "$purge"; then
            result="SUCCESS"
        else
            result="FAILED"
            exit_status=1
        fi

        end_time_ms="$(current_time_ms)" || return $?
        format_module_duration "$((end_time_ms - start_time_ms))" duration
        print_module_footer "$result" "$duration" \
            "$title succeeded" "$title failed"

        results+=("$result")
        durations+=("$duration")

        printf '\n'
    done

    total_end_time_ms="$(current_time_ms)" || return $?
    format_total_duration "$((total_end_time_ms - total_start_time_ms))" total_duration

    print_run_results "$title Results" "$total_duration" \
        __MODULE_NAMES canonical_ids results durations

    if ! delete_all_messages; then
        tlog_error "removal" "Failed to delete stored removal messages"
    fi

    return "$exit_status"
}

main() {
    local -A options=()
    local -a args=()
    local -a canonical_ids=()
    local -a filtered_ids=()
    local help_topic="remove"
    local status=0

    __parse_args options args "$@" || status=$?
    if (( status == 0 )); then
        __validate_options options args || status=$?
    fi

    if (( status != 0 )); then
        if (( options[PURGE] )); then
            help_topic="purge"
        fi
        bash "$MP_COMMAND/help.sh" "$help_topic" >&2

        return "$status"
    fi

    if (( EUID == 0 )); then
        log_error "Do not run 'mp remove' with sudo or as root"
        log_error "Module removal scripts invoke sudo themselves only when necessary"

        return 2
    fi

    if ! resolve_module_selectors canonical_ids "${args[@]}"; then
        log_error "Removal aborted because one or more modules could not be resolved"

        return 2
    fi

    if ! filter_removable_modules \
        "${options[FORCE]}" filtered_ids __MODULE_NAMES "${canonical_ids[@]}"; then
        log_error "Removal aborted because module filtering failed"

        return 1
    fi

    if (( ${#filtered_ids[@]} == 0 )); then
        log_info "No modules require removal."

        return 0
    fi

    if (( options[PURGE] )); then
        __confirm_purge "${filtered_ids[@]}" || return $?
    fi

    cache_sudo_privileges || return $?
    __run_removal "${options[PURGE]}" "${filtered_ids[@]}"
}

main "$@"
