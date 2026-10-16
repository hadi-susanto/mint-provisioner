#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_RUN_REPORT_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_RUN_REPORT_LOADED=1

source "$LIB_COMMON/common.sh"
source "$LIB_INSTALLER/messages.sh"

##
# current_time_ms
#
# Prints the current time in milliseconds since the epoch.
#
# Output:
#   Prints the timestamp.
#
# Return:
#   1 - The time could not be read.
#
current_time_ms() {
    local current_time

    if ! current_time="$(date +%s%3N)" ||
        [[ ! "$current_time" =~ ^[0-9]+$ ]]; then
        log_error "Unable to read the current time in milliseconds"

        return 1
    fi

    printf '%s\n' "$current_time"
}

##
# format_module_duration
#
# Formats a per-module duration, such as "1.234 second(s)".
#
# Parameters:
#   duration_ms - Duration in milliseconds.
#   result_name - Name of the variable that receives the text.
#
format_module_duration() {
    local duration_ms="$1"
    local result_name="$2"
    local -n result_ref="$result_name"

    printf -v result_ref '%d.%03d second(s)' \
        "$((duration_ms / 1000))" "$((duration_ms % 1000))"
}

##
# format_total_duration
#
# Formats a total duration as MM:SS.mmm.
#
# Parameters:
#   duration_ms - Duration in milliseconds.
#   result_name - Name of the variable that receives the text.
#
format_total_duration() {
    local duration_ms="$1"
    local result_name="$2"
    local -n result_ref="$result_name"
    local total_seconds=$((duration_ms / 1000))

    printf -v result_ref '%02d:%02d.%03d' \
        "$((total_seconds / 60))" \
        "$((total_seconds % 60))" \
        "$((duration_ms % 1000))"
}

##
# print_module_header
#
# Prints the banner shown before a module is processed.
#
# Parameters:
#   action - Progressive action label, such as "Installing".
#   canonical_id - Canonical module ID.
#   name - Display name.
#   description - Optional module description.
#
# Output:
#   Prints the header.
#
print_module_header() {
    local action="$1"
    local canonical_id="$2"
    local name="$3"
    local description="${4:-}"

    printf '%s\n' \
        '----------------------------------------------------------------------'
    printf '%s: %b%s%b\n' "$action" "$COLOR_BLUE" "$name" "$COLOR_RESET"
    printf 'Module ID : %b%s%b\n' "$COLOR_YELLOW" "$canonical_id" "$COLOR_RESET"
    if [[ -n "$description" ]]; then
        printf '%s\n' "$description"
    fi
    printf '%s\n' \
        '----------------------------------------------------------------------'
}

##
# print_module_footer
#
# Prints the banner shown after a module is processed.
#
# Parameters:
#   status - SUCCESS or any other value for failure.
#   duration - Formatted duration text.
#   success_text - Text printed on success, such as "Installation succeeded".
#   failure_text - Text printed on failure.
#
# Output:
#   Prints the footer.
#
print_module_footer() {
    local status="$1"
    local duration="$2"
    local success_text="$3"
    local failure_text="$4"
    local status_text
    local status_color

    if [[ "$status" == "SUCCESS" ]]; then
        status_text="$success_text"
        status_color="$COLOR_GREEN"
    else
        status_text="$failure_text"
        status_color="$COLOR_RED"
    fi

    printf '%s\n' \
        '----------------------------------------------------------------------'
    printf -- '-= %b%s%b =- [duration: %b%s%b]\n' \
        "$status_color" "$status_text" "$COLOR_RESET" \
        "$COLOR_CYAN" "$duration" "$COLOR_RESET"
    printf '%s\n' \
        '----------------------------------------------------------------------'
}

##
# print_run_results
#
# Prints the numbered result summary for a multi-module run, followed by each
# module's stored messages.
#
# Parameters:
#   title - Summary title, such as "Installation Results".
#   total_duration - Formatted total duration.
#   names_name - Name of the associative array mapping canonical IDs to names.
#   ids_name - Name of the indexed array of canonical IDs.
#   results_name - Name of the indexed array of SUCCESS/FAILED values.
#   durations_name - Name of the indexed array of formatted durations.
#
# Output:
#   Prints the summary.
#
print_run_results() {
    local title="$1"
    local total_duration="$2"
    local names_name="$3"
    local ids_name="$4"
    local results_name="$5"
    local durations_name="$6"
    local -n names_ref="$names_name"
    local -n ids_ref="$ids_name"
    local -n results_ref="$results_name"
    local -n durations_ref="$durations_name"
    local canonical_id
    local result_color
    local index
    local message_status

    printf '%s [time: %s]\n' "$title" "$total_duration"
    printf '%s\n' '=================================================='

    for (( index = 0; index < ${#ids_ref[@]}; index += 1 )); do
        if [[ "${results_ref[$index]}" == "SUCCESS" ]]; then
            result_color="$COLOR_GREEN"
        else
            result_color="$COLOR_RED"
        fi

        canonical_id="${ids_ref[$index]}"
        printf '%2d. %b%s%b %b[id: %s]%b %b[%s: %s]%b\n' \
            "$((index + 1))" \
            "$COLOR_BLUE" "${names_ref[$canonical_id]:-$canonical_id}" "$COLOR_RESET" \
            "$COLOR_YELLOW" "$canonical_id" "$COLOR_RESET" \
            "$result_color" "${results_ref[$index]}" "${durations_ref[$index]}" "$COLOR_RESET"

        if has_messages "$canonical_id"; then
            if ! print_messages "$canonical_id" 2; then
                tlog_error "run-report:$canonical_id" "Failed to print stored messages"
            fi
        else
            message_status=$?

            if (( message_status > 1 )); then
                tlog_error "run-report:$canonical_id" "Failed to inspect stored messages"
            fi
        fi
    done
}
