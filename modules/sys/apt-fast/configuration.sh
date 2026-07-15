#!/usr/bin/env bash

source "${LIB_DIR}/common.sh"
source "${LIB_DIR}/state.sh"

if [[ "${NONINTERACTIVE:-false}" == "true" ]]; then
    set_state \
        "APT_FAST_PACKAGE_MANAGER" \
        "${APT_FAST_PACKAGE_MANAGER:-apt-get}"

    set_state \
        "APT_FAST_MAX_CONNECTION" \
        "${APT_FAST_MAX_CONNECTION:-5}"

    set_state \
        "APT_FAST_SUPPRESS_CONFIRM_DIALOG" \
        "${APT_FAST_SUPPRESS_CONFIRM_DIALOG:-false}"

    save_states "$CANONICAL_ID" || exit $?

    exit 0
fi

source "${LIB_DIR}/prompt.sh"

__ask_apt_fast_package_manager() {
    local selected_index
    local package_manager

    selected_index="$(
        choose_option \
            "Package manager to install and remove software:" \
            "apt-get" \
            "apt" \
            "aptitude"
    )" || return $?

    case "$selected_index" in
        0)
            package_manager="apt-get"
            ;;

        1)
            package_manager="apt"
            ;;

        2)
            package_manager="aptitude"
            ;;

        *)
            log_error \
                "[$CANONICAL_ID] Unexpected apt-fast package manager selection index: $selected_index"

            return 1
            ;;
    esac

    set_state \
        "APT_FAST_PACKAGE_MANAGER" "$package_manager"
    log_info "[$CANONICAL_ID] $package_manager was chosen as apt-fast package manager"

    return 0
}

if [[ -n "${APT_FAST_PACKAGE_MANAGER:-}" ]]; then
    set_state "APT_FAST_PACKAGE_MANAGER" "$APT_FAST_PACKAGE_MANAGER"
else
    __ask_apt_fast_package_manager || exit $?
    printf "\n"
fi

__ask_apt_fast_max_connection() {
    local max_connection

    max_connection="$(ask_number "Maximum number of connections" "5" "1" "10")" || return $?

    set_state \
        "APT_FAST_MAX_CONNECTION" "$max_connection"
    log_info "[$CANONICAL_ID] apt-fast maximum connection is: $max_connection"

    return 0
}

if [[ -n "${APT_FAST_MAX_CONNECTION:-}" ]]; then
    set_state "APT_FAST_MAX_CONNECTION" "$APT_FAST_MAX_CONNECTION"
else
    __ask_apt_fast_max_connection || exit $?
    printf "\n"
fi

__ask_apt_fast_suppress_confirm_dialog() {
    local selected_index
    local question="This does not affect the package manager's own confirmation dialog. apt-fast will download the installable packages before the package manager asks for confirmation.

Suppress apt-fast confirmation dialog?"

    selected_index="$(
        choose_option \
            "$question" \
            "Yes, Suppress any confirmation dialog" \
            "No, Ask for user confirmation whenever required"
    )" || return $?

    if ((selected_index == 0)); then
        set_state "APT_FAST_SUPPRESS_CONFIRM_DIALOG" "true"
        log_info "[$CANONICAL_ID] Will configure to suppress apt-fast confirmation dialog"
    else
        set_state "APT_FAST_SUPPRESS_CONFIRM_DIALOG" "false"
        log_info "[$CANONICAL_ID] Will configure to show apt-fast confirmation dialog"
    fi

    return 0
}

if [[ -n "${APT_FAST_SUPPRESS_CONFIRM_DIALOG:-}" ]]; then
    set_state "APT_FAST_SUPPRESS_CONFIRM_DIALOG" "$APT_FAST_SUPPRESS_CONFIRM_DIALOG"
else
    __ask_apt_fast_suppress_confirm_dialog || exit $?
    printf "\n"
fi

save_states "$CANONICAL_ID" || exit $?

exit 0
