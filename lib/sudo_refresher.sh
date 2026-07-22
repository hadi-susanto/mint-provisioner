#!/usr/bin/env bash

if (( ${__SUDO_REFRESHER_LIB_LOADED:-0} )); then
    return 0
fi

readonly __SUDO_REFRESHER_LIB_LOADED=1

source "${LIB_DIR}/common.sh"

##
# start_sudo_refresher <context> <result_name> <sleep_duration>
#
# Starts a background task that refreshes cached sudo credentials after each
# configured sleep interval.
#
# Parameters:
#   context          Operation or module identifier used for logging.
#   result_name      Caller-provided variable receiving the background PID.
#   sleep_duration   Positive integer number of seconds between refreshes.
#
# Returns:
#   1 when the required arguments or sleep duration are invalid.
#
start_sudo_refresher() {
    if (( $# != 3 )); then
        log_error \
            "[start_sudo_refresher] Expected context, result_name, and sleep_duration"

        return 1
    fi

    local context="$1"
    local result_name="$2"
    local sleep_duration="$3"

    if [[ -z "$context" ]]; then
        log_error "[start_sudo_refresher] Context must not be empty"

        return 1
    fi

    if [[ ! "$result_name" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
        log_error "[$context] Invalid sudo refresher result variable: $result_name"

        return 1
    fi

    if [[ ! "$sleep_duration" =~ ^[1-9][0-9]*$ ]]; then
        log_error "[$context] Sudo refresh sleep duration must be a positive integer"

        return 1
    fi

    declare -n result_ref="$result_name"

    (
        local sleep_pid=""

        trap '
            if [[ -n "$sleep_pid" ]]; then
                kill "$sleep_pid" 2>/dev/null || true
            fi

            exit 0
        ' TERM INT

        while true; do
            sleep "$sleep_duration" &
            sleep_pid=$!

            if ! wait "$sleep_pid"; then
                exit 0
            fi

            sleep_pid=""

            if sudo -n -v; then
                log_info "[$context] Refreshed sudo credentials"
            else
                log_warn "[$context] Failed to refresh sudo credentials"
                log_info "[$context] Stopping the refresher"
                
                break
            fi
        done
    ) &

    result_ref=$!

    log_info \
        "[$context] Started sudo credential refresher every $sleep_duration second(s)"

    return 0
}

##
# stop_sudo_refresher <context> <refresh_pid>
#
# Stops and reaps a sudo credential refresher task.
#
# Parameters:
#   context         Operation or module identifier used for logging.
#   refresh_pid     Background refresher process ID.
#
# Returns:
#   1 when a running refresher process cannot be stopped.
#
stop_sudo_refresher() {
    local context="${1:-}"
    local refresh_pid="${2:-}"

    if [[ -z "$refresh_pid" ]]; then
        return 0
    fi

    if kill -0 "$refresh_pid" 2>/dev/null; then
        if ! kill "$refresh_pid" 2>/dev/null; then
            log_error "[$context] Failed to stop sudo credential refresher"

            return 1
        fi
    fi

    wait "$refresh_pid" 2>/dev/null || true

    log_info "[$context] Sudo credential refresher stopped"

    return 0
}
