#!/usr/bin/env bash
set -euo pipefail

source "$LIB_COMMON/common.sh"
source "$LIB_COMMON/metadata.sh"
source "$LIB_COMMON/resolver.sh"
source "$LIB_COMMON/run-report.sh"
source "$LIB_COMMON/sudo.sh"
source "$LIB_INSTALLER/messages.sh"
source "$LIB_UPDATER/apt-versioning.sh"
source "$LIB_UPDATER/upgrader.sh"
source "$LIB_UPDATER/versioning.sh"

# Per-run state, filled by __collect_upgrades and read by __print_queue and
# __run_upgrades.
declare -a __UPGRADE_QUEUE=()
declare -A __UPGRADE_NAMES=()
declare -A __UPGRADE_INSTALLED=()
declare -A __UPGRADE_LATEST=()
__FAILED=0

__parse_args() {
    local options_name="$1"
    local args_name="$2"
    shift 2

    local -n options_ref="$options_name"
    local -n args_ref="$args_name"

    options_ref=(
        [HELP]=0
        [YES]=0
    )
    args_ref=()

    while (( $# > 0 )); do
        case "$1" in
            -h | --help)
                options_ref[HELP]=1
                shift
                ;;
            -y | --yes)
                options_ref[YES]=1
                shift
                ;;
            --)
                shift
                args_ref+=("$@")
                break
                ;;
            -*)
                log_error "Unsupported upgrade option: %s" "$1"

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

##
# __find_outdated <explicit> <rows_name> <canonical_id...>
#
# Runs mp outdated --porcelain and stores its rows (canonical ID,
# installed version, latest version separated by tabs) in <rows_name>. The
# version table and logs go to stderr. Selected modules are passed on; without
# a selection, outdated checks every installed module. Sets __FAILED when
# detection or a version query fails.
#
# Return:
#   Other - mp outdated failed with a usage or setup error.
#
__find_outdated() {
    local explicit="$1"
    local -n rows_ref="$2"
    shift 2

    local -a outdated_args=(--porcelain)
    local status=0

    if (( explicit )); then
        outdated_args+=(-- "$@")
    fi

    rows_ref="$(bash "$MP_COMMAND/outdated.sh" "${outdated_args[@]}")" || status=$?
    if (( status > 1 )); then
        log_error "Upgrade aborted because the version check failed"

        return "$status"
    fi

    if (( status == 1 )); then
        __FAILED=1
    fi

    return 0
}

##
# __collect_upgrades <rows>
#
# Queues each outdated module from mp outdated --porcelain rows in
# __UPGRADE_QUEUE when module_upgradable accepts it, and reports the
# others as not upgradable yet.
#
# Return:
#   1 when module metadata cannot be parsed.
#
__collect_upgrades() {
    local rows="$1"
    local -A module_metadata=()
    local row
    local canonical_id
    local installed
    local latest

    # Split on tabs by hand: read collapses consecutive tabs because tab is IFS
    # whitespace, which would shift LATEST into an empty INSTALLED column.
    while IFS= read -r row; do
        [[ -n "$row" ]] || continue

        canonical_id="${row%%$'\t'*}"
        row="${row#*$'\t'}"
        installed="${row%%$'\t'*}"
        latest="${row#*$'\t'}"

        module_metadata=()
        if ! parse_module_metadata "$MP_MODULES/$canonical_id" module_metadata; then
            log_error "Failed to read metadata for %s" "$canonical_id"

            return 1
        fi

        if ! module_upgradable "$canonical_id" module_metadata; then
            log_warn "%s: not upgradable yet (UPDATE_MODE=%s)" \
                "$canonical_id" "${module_metadata[UPDATE_MODE]:-}"

            continue
        fi

        __UPGRADE_QUEUE+=("$canonical_id")
        __UPGRADE_NAMES["$canonical_id"]="${module_metadata[NAME]:-$canonical_id}"
        __UPGRADE_INSTALLED["$canonical_id"]="${installed:-[unknown]}"
        __UPGRADE_LATEST["$canonical_id"]="$latest"
    done <<< "$rows"

    return 0
}

##
# __print_queue
#
# Prints the queued modules as a NAME, CURRENT, LATEST table. Widths are
# computed without color codes.
#
__print_queue() {
    local canonical_id
    local label
    local name_width=4
    local current_width=7

    for canonical_id in "${__UPGRADE_QUEUE[@]}"; do
        label="${__UPGRADE_NAMES[$canonical_id]}"
        if (( ${#label} > name_width )); then
            name_width=${#label}
        fi

        if (( ${#__UPGRADE_INSTALLED[$canonical_id]} > current_width )); then
            current_width=${#__UPGRADE_INSTALLED[$canonical_id]}
        fi
    done

    printf '\n%-*s  %-*s  %s\n' "$name_width" "NAME" "$current_width" "CURRENT" "LATEST"

    for canonical_id in "${__UPGRADE_QUEUE[@]}"; do
        label="${__UPGRADE_NAMES[$canonical_id]}"
        printf '%b%s%b%*s  %-*s  %b%s%b\n' \
            "$COLOR_BLUE" "$label" "$COLOR_RESET" \
            "$(( name_width - ${#label} ))" "" \
            "$current_width" "${__UPGRADE_INSTALLED[$canonical_id]}" \
            "$COLOR_GREEN" "${__UPGRADE_LATEST[$canonical_id]}" "$COLOR_RESET"
    done
}

##
# __confirm_upgrade <count>
#
# Asks whether to upgrade the queued modules. The plain-bash prompt is forced
# so the question appears below the queue instead of hiding it behind a
# whiptail dialog.
#
# Return:
#   0 - The user answered yes.
#   1 - The user answered no.
#   2 - No terminal is available or the answer could not be read.
#
__confirm_upgrade() {
    local count="$1"
    local DISABLE_WHIPTAIL=true

    if [[ ! -t 0 || ! -t 1 ]]; then
        return 2
    fi

    if ! source "$LIB_INSTALLER/prompt.sh"; then
        return 2
    fi

    printf '\n'
    ask_confirm "Upgrade $count module(s)?"
}

__run_upgrades() {
    local -A module_metadata=()
    local canonical_id
    local start_time_ms
    local end_time_ms
    local total_start_time_ms
    local total_end_time_ms
    local duration
    local total_duration
    local result
    local exit_status=0
    local -a durations=()
    local -a results=()

    if ! delete_all_messages; then
        tlog_error "upgrade" "Failed to clear messages from a previous run"
    fi

    total_start_time_ms="$(current_time_ms)" || return $?

    for canonical_id in "${__UPGRADE_QUEUE[@]}"; do
        print_module_header \
            "Upgrading" \
            "$canonical_id" \
            "${__UPGRADE_NAMES[$canonical_id]}"

        module_metadata=()

        start_time_ms="$(current_time_ms)" || return $?
        if parse_module_metadata "$MP_MODULES/$canonical_id" module_metadata &&
            upgrade_module "$canonical_id" module_metadata; then
            result="SUCCESS"
        else
            result="FAILED"
            exit_status=1
        fi

        end_time_ms="$(current_time_ms)" || return $?
        format_module_duration "$((end_time_ms - start_time_ms))" duration
        print_module_footer "$result" "$duration" \
            "Upgrade succeeded" "Upgrade failed"

        results+=("$result")
        durations+=("$duration")

        printf '\n'
    done

    total_end_time_ms="$(current_time_ms)" || return $?
    format_total_duration "$((total_end_time_ms - total_start_time_ms))" total_duration

    print_run_results "Upgrade Results" "$total_duration" \
        __UPGRADE_NAMES __UPGRADE_QUEUE results durations

    if ! delete_all_messages; then
        tlog_error "upgrade" "Failed to delete stored upgrade messages"
    fi

    return "$exit_status"
}

main() {
    local -A options=()
    local -a args=()
    local -a canonical_ids=()
    local -a original_args=("$@")
    local rows=""
    local explicit=0
    local status=0

    __parse_args options args "$@" || status=$?
    if (( status != 0 )); then
        bash "$MP_COMMAND/help.sh" upgrade >&2

        return "$status"
    fi

    if (( options[HELP] )); then
        bash "$MP_COMMAND/help.sh" upgrade

        return 0
    fi

    if (( EUID == 0 )); then
        log_error "Do not run 'mp upgrade' with sudo or as root"
        log_error "Module upgrades invoke sudo themselves only when necessary"

        return 2
    fi

    if (( ${#args[@]} > 0 )); then
        explicit=1

        if ! resolve_module_selectors canonical_ids "${args[@]}"; then
            log_error "Upgrade aborted because one or more modules could not be resolved"

            return 2
        fi
    else
        list_modules canonical_ids || return $?
    fi

    uses_update_mode apt "${canonical_ids[@]}" || status=$?
    if (( status == 0 )); then
        offer_apt_cache_refresh "${options[YES]}"
    elif (( status != 1 )); then
        log_error "Upgrade aborted because module metadata could not be read"

        return 1
    fi

    __find_outdated "$explicit" rows "${canonical_ids[@]}" || return $?
    __collect_upgrades "$rows" || return $?

    if (( ${#__UPGRADE_QUEUE[@]} == 0 )); then
        log_info "No modules require upgrading."

        return "$__FAILED"
    fi

    __print_queue

    if (( options[YES] )); then
        validate_sudo_privileges upgrade "${original_args[@]}" || return $?
    else
        status=0
        __confirm_upgrade "${#__UPGRADE_QUEUE[@]}" || status=$?
        if (( status == 1 )); then
            log_info "Upgrade not started."

            return "$__FAILED"
        fi

        if (( status != 0 )); then
            log_error "Upgrade not started: confirmation requires a terminal; use -y to skip it"

            return 2
        fi

        cache_sudo_privileges || return $?
    fi

    printf '\n'
    __run_upgrades || return $?

    return "$__FAILED"
}

main "$@"
