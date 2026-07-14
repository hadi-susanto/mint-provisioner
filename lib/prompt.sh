#!/usr/bin/env bash

#
# Prevent the library from being loaded more than once.
#
if [[ "${__PROMPT_LIB_LOADED:-false}" == "true" ]]; then
    return 0
fi

readonly __PROMPT_LIB_LOADED="true"

##
# Moves the terminal cursor upward by a specified number of lines.
#
# Arguments:
#   $1 - Optional. Number of lines to move upward. Defaults to 1.
#
# Returns:
#   0
#
cursor_up() {
    local lines="${1:-1}"

    printf '\033[%dA' "$lines" >/dev/tty
}

##
# Clears the current terminal line and moves the cursor to the beginning.
#
# Returns:
#   0
#
clear_line() {
    printf '\033[2K\r' >/dev/tty
}

##
# Clears a specified number of lines above the current cursor position.
#
# The cursor is left at the beginning of the highest cleared line.
#
# Arguments:
#   $1 - Optional. Number of previous lines to clear. Defaults to 1.
#
# Returns:
#   0
#
clear_previous_lines() {
    local line_count="${1:-1}"
    local index

    for ((index = 0; index < line_count; index++)); do
        cursor_up
        clear_line
    done
}

##
# Prints an error message in red to the controlling terminal.
#
# Arguments:
#   $@ - Error message to print.
#
# Returns:
#   0
#
print_input_error() {
    printf '\033[0;31m%s\033[0m\n' "$*" >/dev/tty
}

##
# Temporarily displays an error message and clears the error and input lines.
#
# The error must fit on a single terminal line. If the message wraps onto
# multiple lines, the cursor-clearing behavior may not work correctly.
#
# Arguments:
#   $1 - Error message.
#   $2 - Optional. Number of seconds to display the error. Defaults to 1.
#
# Returns:
#   0
#
show_temporary_input_error() {
    local message="$1"

    print_input_error "$message"

    # Clear the error line and the previous input line.
    cursor_up 2
    clear_line
}

##
# Prints a question and its available numbered options.
#
# Arguments:
#   $1 - Question to display.
#   $@ - Remaining arguments are the available options.
#
# Returns:
#   0
#
__write_questions() {
    local question="$1"
    shift

    local option
    local index=1

    printf '%s\n' "$question" >/dev/tty

    for option in "$@"; do
        printf '  %d. %s\n' \
            "$index" \
            "$option" >/dev/tty

        ((index++))
    done
}

##
# Repeatedly asks the user to select a valid option number.
#
# Invalid input is displayed temporarily in red. The error and invalid input
# lines are then cleared before the user is prompted again.
#
# Arguments:
#   $1 - Total number of available options.
#
# Output:
#   Prints the selected one-based option number to stdout.
#
# Returns:
#   0 when a valid option number is entered.
#   1 when terminal input cannot be read.
#
__loop_ask_answer() {
    local option_count="$1"
    local selected
    local selected_number

    while true; do
        printf 'Choose an option [1-%d]: ' "$option_count" >/dev/tty

        if ! IFS= read -r selected </dev/tty; then
            printf '\nUnable to read user input.\n' >&2
            return 1
        fi

        if [[ "$selected" =~ ^[0-9]+$ ]]; then
            # Force decimal interpretation so values such as 08 are not treated
            # as invalid octal numbers by shell arithmetic.
            selected_number=$((10#$selected))

            if ((selected_number >= 1 && selected_number <= option_count)); then
                printf '%d\n' "$selected_number"
                return 0
            fi
        fi

        show_temporary_input_error \
            "Invalid choice. Enter a number between 1 and $option_count."
    done
}

##
# Repeatedly asks the user to confirm a selected value.
#
# Pressing Enter accepts the value because yes is the default.
#
# Arguments:
#   $1 - Selected value to confirm.
#
# Returns:
#   0 when the user confirms the value.
#   1 when the user rejects the value.
#   2 when terminal input cannot be read.
#
__loop_user_confirmation() {
    local selected_value="$1"
    local confirmation

    while true; do
        printf 'You selected "%s". Use this value? [Y/n]: ' \
            "$selected_value" >/dev/tty

        if ! IFS= read -r confirmation </dev/tty; then
            printf '\nUnable to read user input.\n' >&2
            return 2
        fi

        case "$confirmation" in
            '' | [Yy] | [Yy][Ee][Ss])
                return 0
                ;;

            [Nn] | [Nn][Oo])
                return 1
                ;;

            *)
                show_temporary_input_error \
                    'Invalid confirmation. Enter Y or N.'
                ;;
        esac
    done
}

##
# Prompts the user to select and confirm one value from a list of options.
#
# The first argument is the question. All remaining arguments are selectable
# option values.
#
# Invalid option input is displayed temporarily in red. The error and invalid
# input lines are then cleared before the input prompt is displayed again.
#
# Confirmation defaults to yes when the user presses Enter. When the user
# rejects the selected value, the question and options are printed again.
#
# Usage:
#   selected_value="$(choose_option \
#       "Choose a Brave Browser variant:" \
#       "stable" \
#       "beta" \
#       "nightly")"
#
# Output:
#   Prints the confirmed option value to stdout.
#
# Returns:
#   0 when an option is selected and confirmed.
#   1 when arguments are invalid, no terminal is available, or input fails.
#
choose_option() {
    if (($# < 2)); then
        printf 'choose_option requires a question and at least one option.\n' >&2

        return 1
    fi

    if [[ ! -r /dev/tty || ! -w /dev/tty ]]; then
        printf 'choose_option requires an interactive terminal.\n' >&2

        return 1
    fi

    local question="$1"
    shift

    local -a options=("$@")
    local option_count="${#options[@]}"

    local selected_index
    local selected_option
    local confirmation_status

    while true; do
        __write_questions "$question" "${options[@]}"
        printf '\n' >/dev/tty

        if ! selected_index="$(__loop_ask_answer "$option_count")"; then
            return 1
        fi

        selected_option="${options[$((selected_index - 1))]}"

        if __loop_user_confirmation "$selected_option"; then
            printf '%s\n' "$((selected_index - 1))"

            return 0
        else
            # Need to capture the return code ASAP.
            confirmation_status=$?
        fi

        case "$confirmation_status" in
            1)
                printf '\n' >/dev/tty
                ;;

            *)
                return 1
                ;;
        esac
    done
}
