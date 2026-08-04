#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_SUDO_REFRESHER_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_SUDO_REFRESHER_LOADED=1

source "$LIB_COMMON/common.sh"

##
# start_sudo_refresher
#
# Starts a background task that periodically refreshes cached sudo credentials.
#
# Parameters:
#   context - Generic logging label for the operation using the refresher.
#   result_name - Name of the scalar variable receiving the background PID.
#   interval - Positive number of seconds between credential refreshes.
#
# Return:
#   0 - The sudo refresher was started and its PID was assigned.
#   1 - Validation failed or the background refresher could not be started.
#
start_sudo_refresher() {
    local context="${1:-}"
    local result_name="${2:-}"
    local interval="${3:-}"
    local tag="${context:-sudo-refresher}"

    if (( $# != 3 )) || [[ -z "$context" ]] ||
        [[ ! "$result_name" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] ||
        [[ ! "$interval" =~ ^[1-9][0-9]*$ ]]; then
        tlog_error "$tag" "A context, result variable, and positive interval are required"

        return 1
    fi

    local -n result_ref="$result_name"
    local ready_file
    local refresh_pid
    local attempt

    if ! ready_file="$(mktemp)"; then
        tlog_error "$tag" "Failed to create sudo-refresher readiness marker"

        return 1
    fi

    # The background process will recreate this file after it has verified
    # the current sudo credentials.
    rm -f "$ready_file"

    (
        local sleep_pid=''

        trap '
            if [[ -n "$sleep_pid" ]]; then
                kill "$sleep_pid" 2>/dev/null || true
            fi

            exit 0
        ' TERM INT

        # Do not report the refresher as ready unless the current sudo
        # credentials are valid and can be refreshed non-interactively.
        if ! sudo -n -v; then
            exit 1
        fi

        if ! : >"$ready_file"; then
            exit 1
        fi

        while true; do
            sleep "$interval" &
            sleep_pid=$!

            if ! wait "$sleep_pid"; then
                exit 0
            fi

            sleep_pid=''

            if sudo -n -v; then
                tlog_info "$tag" "Refreshed sudo credentials"
            else
                tlog_warn "$tag" "Failed to refresh sudo credentials; stopping"

                break
            fi
        done
    ) &

    refresh_pid=$!

    # Wait up to approximately one second for the child to verify sudo and
    # signal that it is ready.
    for (( attempt = 0; attempt < 100; attempt += 1 )); do
        if [[ -e "$ready_file" ]]; then
            break
        fi

        if ! kill -0 "$refresh_pid" 2>/dev/null; then
            wait "$refresh_pid" 2>/dev/null || true
            rm -f "$ready_file"
            tlog_error "$tag" "Sudo refresher failed to start"

            return 1
        fi

        sleep 0.01
    done

    if [[ ! -e "$ready_file" ]]; then
        kill "$refresh_pid" 2>/dev/null || true
        wait "$refresh_pid" 2>/dev/null || true
        rm -f "$ready_file"
        tlog_error "$tag" "Timed out while starting the sudo refresher"

        return 1
    fi

    rm -f "$ready_file"
    result_ref="$refresh_pid"
    tlog_info "$tag" "Started sudo refresher every %d second(s)" "$interval"

    return 0
}

##
# stop_sudo_refresher
#
# Stops and reaps a background sudo refresher.
#
# Parameters:
#   context - Generic logging label for the operation using the refresher.
#   refresh_pid - PID returned by start_sudo_refresher; may be empty.
#
# Return:
#   0 - The refresher was stopped, already stopped, or no PID was supplied.
#   1 - Input is invalid or a running refresher could not be stopped.
#
stop_sudo_refresher() {
    local context="${1:-}"
    local refresh_pid="${2:-}"
    local tag="${context:-sudo-refresher}"

    if (( $# != 2 )) || [[ -z "$context" ]]; then
        tlog_error "$tag" "A context and refresher PID are required"

        return 1
    fi

    if [[ -z "$refresh_pid" ]]; then
        return 0
    fi

    if [[ ! "$refresh_pid" =~ ^[1-9][0-9]*$ ]]; then
        tlog_error "$tag" "Invalid sudo refresher PID: %s" "$refresh_pid"

        return 1
    fi

    if kill -0 "$refresh_pid" 2>/dev/null &&
        ! kill "$refresh_pid" 2>/dev/null; then
        tlog_error "$tag" "Failed to stop sudo refresher"

        return 1
    fi

    wait "$refresh_pid" 2>/dev/null || true
    tlog_info "$tag" "Sudo refresher stopped"

    return 0
}
