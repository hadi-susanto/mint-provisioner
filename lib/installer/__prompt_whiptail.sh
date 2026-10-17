#!/usr/bin/env bash

# Private backend of prompt.sh: dialogs rendered with whiptail.
# Load only through prompt.sh, which owns the load-once guard and the terminal check.
# Any other loader must provide its own guard.

source "$LIB_COMMON/common.sh"

# Forced theme so the dialogs stay blue on systems with another default palette.
__prompt_whiptail_colors='root=white,blue
roottext=white,blue
shadow=,black
window=black,lightgray
border=black,lightgray
title=blue,lightgray
label=black,lightgray
textbox=black,lightgray
acttextbox=black,lightgray
listbox=black,lightgray
actlistbox=white,blue
sellistbox=black,lightgray
actsellistbox=white,blue
checkbox=black,lightgray
actcheckbox=white,blue
entry=black,cyan
disentry=gray,lightgray
button=black,cyan
actbutton=white,blue
compactbutton=black,lightgray
helpline=white,blue
emptyscale=,lightgray
fullscale=,blue'

##
# __prompt_whiptail_run <whiptail_arg>...
#
# Runs whiptail on the controlling terminal and prints the dialog result.
#
# Output:
#   Prints the user's answer (whiptail writes it to stderr, swapped to stdout).
#
# Return:
#   1 - The dialog was cancelled or whiptail failed.
#
__prompt_whiptail_run() {
    local status

    if env -u NEWT_COLORS_FILE NEWT_COLORS="$__prompt_whiptail_colors" \
        whiptail "$@" 3>&1 1>&2 2>&3 </dev/tty >/dev/tty; then
        return 0
    else
        status=$?
    fi

    tlog_error "prompt" "Dialog was cancelled or failed (status %s)" "$status"

    return 1
}

__prompt_whiptail_message() {
    local message="$1"

    env -u NEWT_COLORS_FILE NEWT_COLORS="$__prompt_whiptail_colors" \
        whiptail --title "Invalid input" --msgbox "$message" 8 60 \
        </dev/tty >/dev/tty 2>&1 || true
}

##
# choose_option
#
# Prompts for one option in a whiptail menu, then prints its zero-based index.
#
# Parameters:
#   question - Question displayed above the available options.
#   option - One or more selectable option labels.
#
# Output:
#   Prints the selected option's zero-based index to standard output.
#
# Return:
#   0 - An option was selected.
#   1 - Input is invalid or the dialog was cancelled.
#
choose_option() {
    local question="${1:-}"
    local option
    local selected
    local index=1
    local menu_height
    local -a options=()
    local -a menu_args=()

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

        menu_args+=("$index" "$option")
        (( index += 1 ))
    done

    menu_height="${#options[@]}"
    if (( menu_height > 15 )); then
        menu_height=15
    fi

    selected="$(__prompt_whiptail_run --title "Mint Provisioner" --menu \
        "$question" "$(( menu_height + 8 ))" 70 "$menu_height" \
        "${menu_args[@]}")" || return 1

    printf '%d\n' "$((10#$selected - 1))"
}

##
# ask_number
#
# Prompts for a non-negative integer within optional bounds.
#
# Parameters:
#   question - Question displayed before the input field.
#   default_value - Optional value used when the user submits empty input.
#   minimum_value - Optional minimum accepted value.
#   maximum_value - Optional maximum accepted value.
#
# Output:
#   Prints the numeric value to standard output.
#
# Return:
#   0 - A valid numeric value was entered.
#   1 - Input is invalid or the dialog was cancelled.
#
ask_number() {
    local question="${1:-}"
    local default_value="${2-}"
    local minimum_value="${3-}"
    local maximum_value="${4-}"
    local input
    local value
    local prompt_text

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

    prompt_text="$question"
    if [[ -n "$minimum_value" || -n "$maximum_value" ]]; then
        prompt_text+=$'\n'
    fi
    if [[ -n "$minimum_value" ]]; then
        prompt_text+=" [min: $minimum_value]"
    fi
    if [[ -n "$maximum_value" ]]; then
        prompt_text+=" [max: $maximum_value]"
    fi

    while true; do
        input="$(__prompt_whiptail_run --title "Mint Provisioner" --inputbox \
            "$prompt_text" 12 70 "$default_value")" || return 1

        __trim input

        if [[ -z "$input" ]]; then
            if [[ -n "$default_value" ]]; then
                printf '%s\n' "$default_value"

                return 0
            fi

            __prompt_whiptail_message "A value is required."

            continue
        fi

        if [[ ! "$input" =~ ^[0-9]+$ ]]; then
            __prompt_whiptail_message "Invalid value. Enter a number."

            continue
        fi

        value=$((10#$input))

        if [[ -n "$minimum_value" ]] && (( value < 10#$minimum_value )); then
            __prompt_whiptail_message \
                "Invalid value. Enter a number greater than or equal to $minimum_value."

            continue
        fi

        if [[ -n "$maximum_value" ]] && (( value > 10#$maximum_value )); then
            __prompt_whiptail_message \
                "Invalid value. Enter a number less than or equal to $maximum_value."

            continue
        fi

        printf '%d\n' "$value"

        return 0
    done
}

##
# ask_text
#
# Prompts for non-empty trimmed text.
#
# Parameters:
#   question - Question displayed before the input field.
#   default_value - Optional value used when the user submits empty input.
#
# Output:
#   Prints the trimmed text to standard output.
#
# Return:
#   0 - A non-empty text value was entered.
#   1 - Input is invalid or the dialog was cancelled.
#
ask_text() {
    local question="${1:-}"
    local default_value="${2-}"
    local input

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
        input="$(__prompt_whiptail_run --title "Mint Provisioner" --inputbox \
            "$question" 12 70 "$default_value")" || return 1

        __trim input

        if [[ -z "$input" && -n "$default_value" ]]; then
            input="$default_value"
        fi

        if [[ -z "$input" ]]; then
            __prompt_whiptail_message "A value is required."

            continue
        fi

        printf '%s\n' "$input"

        return 0
    done
}

##
# ask_password
#
# Prompts twice for a password in masked whiptail dialogs. The password is not
# trimmed and may be empty.
#
# Parameters:
#   question - Question displayed above the password field.
#
# Output:
#   Prints the confirmed password to standard output.
#
# Return:
#   0 - Both entries matched.
#   1 - Input is invalid or the dialog was cancelled.
#
ask_password() {
    local question="${1:-}"
    local password
    local confirmation

    if (( $# != 1 )) || [[ -z "$question" ]]; then
        tlog_error "prompt" "ask_password requires a question"

        return 1
    fi

    while true; do
        password="$(__prompt_whiptail_run --title "Mint Provisioner" --passwordbox \
            "$question" 12 70)" || return 1
        confirmation="$(__prompt_whiptail_run --title "Mint Provisioner" --passwordbox \
            "Confirm the password." 10 70)" || return 1

        if [[ "$password" != "$confirmation" ]]; then
            __prompt_whiptail_message "Passwords do not match."

            continue
        fi

        printf '%s\n' "$password"

        return 0
    done
}
