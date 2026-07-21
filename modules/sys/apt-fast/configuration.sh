#!/usr/bin/env bash
set -euo pipefail

source "${LIB_DIR}/common.sh"
source "${LIB_DIR}/state.sh"

__resolve_apt_fast_package_manager() {
    local package_manager="${1:-}"

    case "$package_manager" in
        apt-get | apt | aptitude)
            set_state \
                "APT_FAST_PACKAGE_MANAGER" \
                "$package_manager"

            log_info \
                "[$CANONICAL_ID] apt-fast package manager: $package_manager"
            ;;
        *)
            log_error \
                "[$CANONICAL_ID] Invalid apt-fast package manager: $package_manager. Expected apt-get, apt, or aptitude."

            return 1
            ;;
    esac

    return 0
}

__resolve_apt_fast_max_connection() {
    local max_connection="${1:-}"
    local normalized_value

    if [[ ! "$max_connection" =~ ^[0-9]+$ ]]; then
        log_error \
            "[$CANONICAL_ID] Maximum connections must be an integer from 1 to 10: $max_connection"

        return 1
    fi

    normalized_value="$((10#$max_connection))"

    if ((normalized_value < 1 || normalized_value > 10)); then
        log_error \
            "[$CANONICAL_ID] Maximum connections must be between 1 and 10: $max_connection"

        return 1
    fi

    set_state \
        "APT_FAST_MAX_CONNECTION" \
        "$normalized_value"

    log_info \
        "[$CANONICAL_ID] apt-fast maximum connections: $normalized_value"

    return 0
}

__resolve_apt_fast_suppress_confirm_dialog() {
    local suppress_confirm_dialog="${1:-}"

    suppress_confirm_dialog="${suppress_confirm_dialog,,}"

    case "$suppress_confirm_dialog" in
        true | false)
            set_state \
                "APT_FAST_SUPPRESS_CONFIRM_DIALOG" \
                "$suppress_confirm_dialog"

            log_info \
                "[$CANONICAL_ID] Suppress apt-fast confirmation dialog: $suppress_confirm_dialog"
            ;;
        *)
            log_error \
                "[$CANONICAL_ID] Invalid APT_FAST_SUPPRESS_CONFIRM_DIALOG value: $1. Expected true or false."

            return 1
            ;;
    esac

    return 0
}

if [[ "${APT_FAST_NON_INTERACTIVE:-${NON_INTERACTIVE:-false}}" == "true" ]]; then
    __resolve_apt_fast_package_manager \
        "${APT_FAST_PACKAGE_MANAGER:-apt-get}" || exit $?

    __resolve_apt_fast_max_connection \
        "${APT_FAST_MAX_CONNECTION:-5}" || exit $?

    __resolve_apt_fast_suppress_confirm_dialog \
        "${APT_FAST_SUPPRESS_CONFIRM_DIALOG:-false}" || exit $?

    save_states "$CANONICAL_ID" || exit $?

    exit 0
fi

source "${LIB_DIR}/prompt.sh"

__ask_apt_fast_package_manager() {
    local selected_index

    selected_index="$(
        choose_option \
            "Which package manager should apt-fast use?" \
            "apt-get (recommended)" \
            "apt" \
            "aptitude"
    )" || return $?

    case "$selected_index" in
        0)
            __resolve_apt_fast_package_manager "apt-get"
            ;;
        1)
            __resolve_apt_fast_package_manager "apt"
            ;;
        2)
            __resolve_apt_fast_package_manager "aptitude"
            ;;
        *)
            log_error \
                "[$CANONICAL_ID] Unexpected package manager selection index: $selected_index"

            return 1
            ;;
    esac
}

__ask_apt_fast_max_connection() {
    local max_connection

    max_connection="$(
        ask_number \
            "Maximum simultaneous download connections" \
            "5" \
            "1" \
            "10"
    )" || return $?

    __resolve_apt_fast_max_connection "$max_connection"
}

__ask_apt_fast_suppress_confirm_dialog() {
    local selected_index

    selected_index="$(
        choose_option \
            "Suppress the apt-fast confirmation dialog?

The package manager may still ask for confirmation before installation." \
            "Yes, suppress the apt-fast dialog" \
            "No, ask before downloading packages"
    )" || return $?

    case "$selected_index" in
        0)
            __resolve_apt_fast_suppress_confirm_dialog "true"
            ;;
        1)
            __resolve_apt_fast_suppress_confirm_dialog "false"
            ;;
        *)
            log_error \
                "[$CANONICAL_ID] Unexpected confirmation selection index: $selected_index"

            return 1
            ;;
    esac
}

if [[ -n "${APT_FAST_PACKAGE_MANAGER:-}" ]]; then
    __resolve_apt_fast_package_manager \
        "$APT_FAST_PACKAGE_MANAGER" || exit $?
else
    __ask_apt_fast_package_manager || exit $?
    printf '\n'
fi

if [[ -n "${APT_FAST_MAX_CONNECTION:-}" ]]; then
    __resolve_apt_fast_max_connection \
        "$APT_FAST_MAX_CONNECTION" || exit $?
else
    __ask_apt_fast_max_connection || exit $?
    printf '\n'
fi

if [[ -n "${APT_FAST_SUPPRESS_CONFIRM_DIALOG:-}" ]]; then
    __resolve_apt_fast_suppress_confirm_dialog \
        "$APT_FAST_SUPPRESS_CONFIRM_DIALOG" || exit $?
else
    __ask_apt_fast_suppress_confirm_dialog || exit $?
    printf '\n'
fi

save_states "$CANONICAL_ID" || exit $?

exit 0
