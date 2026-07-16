#!/usr/bin/env bash

#
# Prevent the library from being loaded more than once.
#
if (( ${__PROMPT_LIB_LOADED:-0} )); then
    return 0
fi

readonly __PROMPT_LIB_LOADED=1

#
# Define trim() only if it has not already been defined.
#
if ! declare -F trim >/dev/null; then
    trim() {
        local value="$*"

        value="${value#"${value%%[![:space:]]*}"}"
        value="${value%"${value##*[![:space:]]}"}"

        printf '%s' "$value"
    }
fi

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
__write_choose_option_questions() {
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
__loop_choose_option_answer() {
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
        __write_choose_option_questions "$question" "${options[@]}"
        printf '\n' >/dev/tty

        if ! selected_index="$(__loop_choose_option_answer "$option_count")"; then
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

##
# Prints a simple input question with optional constraints.
#
# When a minimum and/or maximum value is provided, the accepted range is
# displayed after the question. When a default value is provided, it is also
# displayed as the default.
#
# Arguments:
#   $1 - Question to display.
#   $2 - Optional. Default value.
#   $3 - Optional. Minimum accepted value.
#   $4 - Optional. Maximum accepted value.
#
# Examples:
#   Enter your name:
#   Enter retry count [1-10] [default: 3]:
#   Enter minimum size [min: 10]:
#   Enter maximum size [max: 100]:
#
# Returns:
#   0
#
__write_simple_question() {
    local question="$1"
    local default_value="${2-}"
    local minimum_value="${3-}"
    local maximum_value="${4-}"

    printf '%s' "$question" >/dev/tty

    if [[ -n "$minimum_value" && -n "$maximum_value" ]]; then
        printf ' [%s-%s]' \
            "$minimum_value" \
            "$maximum_value" >/dev/tty
    elif [[ -n "$minimum_value" ]]; then
        printf ' [min: %s]' \
            "$minimum_value" >/dev/tty
    elif [[ -n "$maximum_value" ]]; then
        printf ' [max: %s]' \
            "$maximum_value" >/dev/tty
    fi

    if [[ -n "$default_value" ]]; then
        printf ' [default: %s]' \
            "$default_value" >/dev/tty
    fi

    printf ': ' >/dev/tty

    return 0
}

##
# Repeatedly asks the user to enter a valid numeric value.
#
# All arguments are expected to have already been validated by ask_number.
#
# When a default value is provided, pressing Enter immediately returns that
# value. When no default value is provided, empty input is rejected.
#
# Arguments:
#   $1 - Optional. Default value.
#   $2 - Optional. Minimum accepted value.
#   $3 - Optional. Maximum accepted value.
#
# Output:
#   Prints the validated numeric value to stdout.
#
# Returns:
#   0 when a valid numeric value is entered.
#   1 when terminal input cannot be read.
#
__loop_ask_number_answer() {
    local default_value="${1-}"
    local minimum_value="${2-}"
    local maximum_value="${3-}"

    local input
    local value

    while true; do
        if ! IFS= read -r input </dev/tty; then
            printf '\nUnable to read user input.\n' >&2

            return 1
        fi

        if [[ -z "$input" ]]; then
            if [[ -n "$default_value" ]]; then
                printf '%s\n' "$default_value"

                return 0
            fi

            show_temporary_input_error \
                'A value is required.'

            continue
        fi

        if [[ ! "$input" =~ ^[0-9]+$ ]]; then
            show_temporary_input_error \
                'Invalid value. Enter a number.'

            continue
        fi

        # Force decimal interpretation so values such as 08 are not treated
        # as octal numbers by shell arithmetic.
        value=$((10#$input))

        if [[ -n "$minimum_value" ]] &&
            ((value < 10#$minimum_value)); then
            show_temporary_input_error \
                "Invalid value. Enter a number greater than or equal to $minimum_value."

            continue
        fi

        if [[ -n "$maximum_value" ]] &&
            ((value > 10#$maximum_value)); then
            show_temporary_input_error \
                "Invalid value. Enter a number less than or equal to $maximum_value."

            continue
        fi

        printf '%d\n' "$value"

        return 0
    done
}


##
# Prompts the user to enter and confirm a numeric value.
#
# When a default value is provided, pressing Enter uses that value. When no
# default value is provided, empty input is rejected.
#
# Optional minimum and maximum values can be used to restrict the accepted
# numeric range.
#
# When the user rejects the entered value during confirmation, the question is
# displayed again.
#
# Arguments:
#   $1 - Question to display.
#   $2 - Optional. Default value.
#   $3 - Optional. Minimum accepted value.
#   $4 - Optional. Maximum accepted value.
#
# Usage:
#   value="$(ask_number "Enter retry count")"
#
#   value="$(ask_number \
#       "Enter retry count" \
#       "3")"
#
#   value="$(ask_number \
#       "Enter retry count" \
#       "3" \
#       "1" \
#       "10")"
#
# Output:
#   Prints the confirmed numeric value to stdout.
#
# Returns:
#   0 when a valid value is entered and confirmed.
#   1 when arguments are invalid, no terminal is available, or input fails.
#
ask_number() {
    if (($# < 1 || $# > 4)); then
        printf '%s\n' \
            'ask_number requires a question and optionally a default, minimum, and maximum value.' >&2

        return 1
    fi

    if [[ ! -r /dev/tty || ! -w /dev/tty ]]; then
        printf '%s\n' \
            'ask_number requires an interactive terminal.' >&2

        return 1
    fi

    local question="$1"
    local default_value="${2-}"
    local minimum_value="${3-}"
    local maximum_value="${4-}"

    local selected_value
    local confirmation_status

    if [[ -z "$question" ]]; then
        printf '%s\n' \
            'ask_number requires a non-empty question.' >&2

        return 1
    fi

    if [[ -n "$default_value" ]]; then
        if [[ ! "$default_value" =~ ^[0-9]+$ ]]; then
            printf '%s\n' \
                "ask_number default value must be numeric: $default_value" >&2

            return 1
        fi

        # Normalize the value and force decimal interpretation so values such as
        # 08 are not treated as octal numbers by shell arithmetic.
        default_value="$((10#$default_value))"
    fi

    if [[ -n "$minimum_value" && ! "$minimum_value" =~ ^[0-9]+$ ]]; then
        printf '%s\n' \
            "ask_number minimum value must be numeric: $minimum_value" >&2

        return 1
    fi

    if [[ -n "$maximum_value" && ! "$maximum_value" =~ ^[0-9]+$ ]]; then
        printf '%s\n' \
            "ask_number maximum value must be numeric: $maximum_value" >&2

        return 1
    fi

    if [[ -n "$minimum_value" && -n "$maximum_value" ]] &&
        ((10#$minimum_value > 10#$maximum_value)); then
        printf '%s\n' \
            'ask_number minimum value must not exceed maximum value.' >&2

        return 1
    fi

    if [[ -n "$default_value" ]]; then
        if [[ -n "$minimum_value" ]] &&
            ((10#$default_value < 10#$minimum_value)); then
            printf '%s\n' \
                "ask_number default value must not be less than $minimum_value." >&2

            return 1
        fi

        if [[ -n "$maximum_value" ]] &&
            ((10#$default_value > 10#$maximum_value)); then
            printf '%s\n' \
                "ask_number default value must not exceed $maximum_value." >&2

            return 1
        fi
    fi

    while true; do
        __write_simple_question \
            "$question" \
            "$default_value" \
            "$minimum_value" \
            "$maximum_value"

        if ! selected_value="$(
            __loop_ask_number_answer \
                "$default_value" \
                "$minimum_value" \
                "$maximum_value"
        )"; then
            return 1
        fi

        if __loop_user_confirmation "$selected_value"; then
            printf '%s\n' "$selected_value"

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

##
# Repeatedly asks the user to enter a non-empty text value.
#
# All arguments are expected to have already been validated by ask_text.
#
# When a default value is provided, pressing Enter immediately returns that
# value. When no default value is provided, empty input is rejected.
#
# Arguments:
#   $1 - Optional. Default value.
#
# Output:
#   Prints the entered text value to stdout.
#
# Returns:
#   0 when a valid text value is entered.
#   1 when terminal input cannot be read.
#
__loop_ask_text_answer() {
    local default_value="${1-}"
    local input

    while true; do
        if ! IFS= read -r input </dev/tty; then
            printf '\nUnable to read user input.\n' >&2

            return 1
        fi
        
        input="$(trim "$input")"

        if [[ -z "$input" ]]; then
            if [[ -n "$default_value" ]]; then
                printf '%s\n' "$default_value"

                return 0
            fi

            show_temporary_input_error \
                'A value is required.'

            continue
        fi

        printf '%s\n' "$input"

        return 0
    done
}

##
# Prompts the user to enter and confirm a non-empty text value.
#
# When a default value is provided, pressing Enter uses that value. When no
# default value is provided, empty input is rejected.
#
# When the user rejects the entered value during confirmation, the question is
# displayed again.
#
# Arguments:
#   $1 - Question to display.
#   $2 - Optional. Default value.
#
# Usage:
#   value="$(ask_text "Enter your name")"
#
#   value="$(ask_text \
#       "Enter your preferred editor" \
#       "vim")"
#
# Output:
#   Prints the confirmed text value to stdout.
#
# Returns:
#   0 when a valid value is entered and confirmed.
#   1 when arguments are invalid, no terminal is available, or input fails.
#
ask_text() {
    if (($# < 1 || $# > 2)); then
        printf '%s\n' \
            'ask_text requires a question and optionally a default value.' >&2

        return 1
    fi

    if [[ ! -r /dev/tty || ! -w /dev/tty ]]; then
        printf '%s\n' \
            'ask_text requires an interactive terminal.' >&2

        return 1
    fi

    local question="$1"
    local default_value="${2-}"

    local selected_value
    local confirmation_status

    question="$(trim "$question")"
    default_value="$(trim "$default_value")"

    if [[ -z "$question" ]]; then
        printf '%s\n' \
            'ask_text requires a non-empty question.' >&2

        return 1
    fi

    while true; do
        __write_simple_question \
            "$question" \
            "$default_value"

        if ! selected_value="$(
            __loop_ask_text_answer \
                "$default_value"
        )"; then
            return 1
        fi

        if __loop_user_confirmation "$selected_value"; then
            printf '%s\n' "$selected_value"

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
