#!/usr/bin/env bash

# Prevent non-interactive session loading prompt.sh
if [[ -n "${NON_INTERACTIVE:-}" ]]; then
    source "$LIB_COMMON/common.sh"
    tlog_error "prompt" "Invalid module; non-interactive session attempted to load prompt.sh"

    return 1
fi

if [[ -n "${__MINT_PROVISIONER_PROMPT_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_PROMPT_LOADED=1

source "$LIB_COMMON/common.sh"

if [[ -r /dev/tty && -w /dev/tty ]] &&
    { : </dev/tty; } 2>/dev/null &&
    { : >/dev/tty; } 2>/dev/null; then
    :
else
    tlog_error "prompt" "An interactive terminal is required to load the prompt library"

    return 1
fi

__prompt_cursor_up() {
    local lines="${1:-1}"

    printf '\033[%dA' "$lines" >/dev/tty
}

__prompt_clear_line() {
    printf '\033[2K\r' >/dev/tty
}

__prompt_show_input_error() {
    printf '%b%s%b\n' "$COLOR_RED" "$1" "$COLOR_RESET" >/dev/tty
    __prompt_cursor_up 2
    __prompt_clear_line
}

__prompt_confirm() {
    local selected_value="$1"
    local confirmation

    while true; do
        printf 'You selected "%s". Use this value? [Y/n]: ' \
            "$selected_value" >/dev/tty

        if ! IFS= read -r confirmation </dev/tty; then
            tlog_error "prompt" "Unable to read user confirmation"

            return 2
        fi

        case "$confirmation" in
            '' | [Yy] | [Yy][Ee][Ss]) return 0 ;;
            [Nn] | [Nn][Oo]) return 1 ;;
            *) __prompt_show_input_error 'Invalid confirmation. Enter Y or N.' ;;
        esac
    done
}

__prompt_write_simple_question() {
    local question="$1"
    local default="${2-}"
    local minimum="${3-}"
    local maximum="${4-}"

    printf '%bQuestion:%b %s' "$COLOR_CYAN" "$COLOR_RESET" "$question" >/dev/tty

    if [[ -n "$minimum" || -n "$maximum" || -n "$default" ]]; then
        printf '\n   %bRules:%b' "$COLOR_YELLOW" "$COLOR_RESET" >/dev/tty
    fi

    if [[ -n "$minimum" ]]; then
        printf ' %b[min: %s]%b' "$COLOR_GRAY" "$minimum" "$COLOR_RESET" >/dev/tty
    fi
    if [[ -n "$maximum" ]]; then
        printf ' %b[max: %s]%b' "$COLOR_GRAY" "$maximum" "$COLOR_RESET" >/dev/tty
    fi
    if [[ -n "$default" ]]; then
        printf ' %b[default: %s]%b' "$COLOR_GRAY" "$default" "$COLOR_RESET" >/dev/tty
    fi

    printf '\n\n' >/dev/tty
}

__prompt_read_number() {
    local default_value="${1-}"
    local minimum_value="${2-}"
    local maximum_value="${3-}"
    local input
    local value

    while true; do
        printf 'Input a number: ' >/dev/tty
        if ! IFS= read -r input </dev/tty; then
            tlog_error "prompt" "Unable to read numeric input"

            return 1
        fi

        if [[ -z "$input" ]]; then
            if [[ -n "$default_value" ]]; then
                printf '%s\n' "$default_value"

                return 0
            fi

            __prompt_show_input_error 'A value is required.'

            continue
        fi

        if [[ ! "$input" =~ ^[0-9]+$ ]]; then
            __prompt_show_input_error 'Invalid value. Enter a number.'

            continue
        fi

        value=$((10#$input))

        if [[ -n "$minimum_value" ]] && (( value < 10#$minimum_value )); then
            __prompt_show_input_error \
                "Invalid value. Enter a number greater than or equal to $minimum_value."

            continue
        fi

        if [[ -n "$maximum_value" ]] && (( value > 10#$maximum_value )); then
            __prompt_show_input_error \
                "Invalid value. Enter a number less than or equal to $maximum_value."

            continue
        fi

        printf '%d\n' "$value"

        return 0
    done
}

__prompt_read_text() {
    local default_value="${1-}"
    local input

    while true; do
        printf 'Answer: ' >/dev/tty
        if ! IFS= read -r input </dev/tty; then
            tlog_error "prompt" "Unable to read text input"

            return 1
        fi

        __trim input

        if [[ -z "$input" && -n "$default_value" ]]; then
            printf '%s\n' "$default_value"

            return 0
        fi

        if [[ -z "$input" ]]; then
            __prompt_show_input_error 'A value is required.'

            continue
        fi

        printf '%s\n' "$input"

        return 0
    done
}

##
# choose_option
#
# Prompts for and confirms one option, then prints its zero-based index.
#
# Parameters:
#   question - Question displayed before the available options.
#   option - One or more selectable option labels.
#
# Output:
#   Prints the confirmed option's zero-based index to standard output.
#
# Return:
#   0 - An option was selected and confirmed.
#   1 - Input is invalid or reading from the terminal failed.
#
choose_option() {
    local question="${1:-}"
    local option
    local selected
    local selected_number
    local selected_option
    local confirmation_status
    local index
    local -a options=()

    if (( $# < 2 )); then
        tlog_error "prompt" "choose_option requires a question and at least one option"

        return 1
    fi

    shift
    options=("$@")
    __trim question

    if [[ -z "$question" ]]; then
        tlog_error "prompt" "The option question must not be empty"

        return 1
    fi

    for option in "${options[@]}"; do
        if [[ -z "$option" ]]; then
            tlog_error "prompt" "Options must not be empty"

            return 1
        fi
    done

    while true; do
        printf '%bQuestion:%b %s\n' "$COLOR_CYAN" "$COLOR_RESET" "$question" >/dev/tty
        index=1
        for option in "${options[@]}"; do
            printf '  %b%d.%b %s\n' "$COLOR_GREEN" "$index" "$COLOR_RESET" "$option" >/dev/tty
            (( index += 1 ))
        done
        printf '\n' >/dev/tty

        while true; do
            printf 'Choose an option %b[1-%d]%b: ' "$COLOR_GREEN" "${#options[@]}" "$COLOR_RESET" >/dev/tty

            if ! IFS= read -r selected </dev/tty; then
                tlog_error "prompt" "Unable to read option input"

                return 1
            fi

            if [[ "$selected" =~ ^[0-9]+$ ]]; then
                selected_number=$((10#$selected))
                if (( selected_number >= 1 && selected_number <= ${#options[@]} )); then
                    break
                fi
            fi

            __prompt_show_input_error \
                "Invalid choice. Enter a number between 1 and ${#options[@]}."
        done
        __prompt_clear_line

        selected_option="${options[$((selected_number - 1))]}"

        if __prompt_confirm "$selected_option"; then
            __prompt_clear_line
            printf '%d\n' "$((selected_number - 1))"

            return 0
        else
            confirmation_status=$?
        fi

        if (( confirmation_status != 1 )); then
            return 1
        fi

        printf '\n' >/dev/tty
    done
}

##
# ask_number
#
# Prompts for and confirms a non-negative integer within optional bounds.
#
# Parameters:
#   question - Question displayed before the input field.
#   default_value - Optional value used when the user submits empty input.
#   minimum_value - Optional minimum accepted value.
#   maximum_value - Optional maximum accepted value.
#
# Output:
#   Prints the confirmed numeric value to standard output.
#
# Return:
#   0 - A valid numeric value was entered and confirmed.
#   1 - Input is invalid or reading from the terminal failed.
#
ask_number() {
    local question="${1:-}"
    local default_value="${2-}"
    local minimum_value="${3-}"
    local maximum_value="${4-}"
    local selected_value
    local confirmation_status

    if (( $# < 1 || $# > 4 )); then
        tlog_error "prompt" "ask_number accepts a question, default, minimum, and maximum"

        return 1
    fi

    __trim question

    if [[ -z "$question" ]]; then
        tlog_error "prompt" "The numeric question must not be empty"

        return 1
    fi

    if [[ -n "$default_value" && ! "$default_value" =~ ^[0-9]+$ ]]; then
        tlog_error "prompt" "Default value must be numeric: %s" "$default_value"

        return 1
    fi

    if [[ -n "$minimum_value" && ! "$minimum_value" =~ ^[0-9]+$ ]]; then
        tlog_error "prompt" "Minimum value must be numeric: %s" "$minimum_value"

        return 1
    fi

    if [[ -n "$maximum_value" && ! "$maximum_value" =~ ^[0-9]+$ ]]; then
        tlog_error "prompt" "Maximum value must be numeric: %s" "$maximum_value"

        return 1
    fi

    if [[ -n "$minimum_value" && -n "$maximum_value" ]] &&
        (( 10#$minimum_value > 10#$maximum_value )); then
        tlog_error "prompt" "Minimum value must not exceed maximum value"

        return 1
    fi

    if [[ -n "$default_value" ]]; then
        default_value="$((10#$default_value))"

        if [[ -n "$minimum_value" ]] && (( default_value < 10#$minimum_value )); then
            tlog_error "prompt" "Default value must not be less than %s" "$minimum_value"

            return 1
        fi

        if [[ -n "$maximum_value" ]] && (( default_value > 10#$maximum_value )); then
            tlog_error "prompt" "Default value must not exceed %s" "$maximum_value"

            return 1
        fi
    fi

    while true; do
        __prompt_write_simple_question \
            "$question" "$default_value" "$minimum_value" "$maximum_value"

        selected_value="$(__prompt_read_number \
            "$default_value" "$minimum_value" "$maximum_value")" || return $?
        __prompt_clear_line

        if __prompt_confirm "$selected_value"; then
            __prompt_clear_line
            printf '%s\n' "$selected_value"

            return 0
        else
            confirmation_status=$?
        fi

        if (( confirmation_status != 1 )); then
            return 1
        fi

        printf '\n' >/dev/tty
    done
}

##
# ask_text
#
# Prompts for and confirms non-empty trimmed text.
#
# Parameters:
#   question - Question displayed before the input field.
#   default_value - Optional value used when the user submits empty input.
#
# Output:
#   Prints the confirmed trimmed text to standard output.
#
# Return:
#   0 - A non-empty text value was entered and confirmed.
#   1 - Input is invalid or reading from the terminal failed.
#
ask_text() {
    local question="${1:-}"
    local default_value="${2-}"
    local selected_value
    local confirmation_status

    if (( $# < 1 || $# > 2 )); then
        tlog_error "prompt" "ask_text accepts a question and optional default"

        return 1
    fi

    __trim question
    __trim default_value

    if [[ -z "$question" ]]; then
        tlog_error "prompt" "The text question must not be empty"

        return 1
    fi

    while true; do
        __prompt_write_simple_question "$question" "$default_value"
        selected_value="$(__prompt_read_text "$default_value")" || return $?
        __prompt_clear_line

        if __prompt_confirm "$selected_value"; then
            __prompt_clear_line
            printf '%s\n' "$selected_value"

            return 0
        else
            confirmation_status=$?
        fi

        if (( confirmation_status != 1 )); then
            return 1
        fi

        printf '\n' >/dev/tty
    done
}
