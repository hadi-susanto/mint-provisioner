#!/usr/bin/env bash
set -euo pipefail

source "${LIB_INSTALLER}/prompt.sh"
source "$LIB_WORKFLOW/$CANONICAL_ID/resolver.sh"

tag="interactive:$CANONICAL_ID"

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
            resolve_apt_fast_package_manager "apt-get"
            ;;
        1)
            resolve_apt_fast_package_manager "apt"
            ;;
        2)
            resolve_apt_fast_package_manager "aptitude"
            ;;
        *)
            tlog_error "$tag" \
                "Unexpected package manager selection index: %s" "$selected_index"

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

    resolve_apt_fast_max_connection "$max_connection"
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
            resolve_apt_fast_suppress_confirm_dialog "true"
            ;;
        1)
            resolve_apt_fast_suppress_confirm_dialog "false"
            ;;
        *)
            tlog_error "$tag" \
                "Unexpected confirmation selection index: %s" "$selected_index"

            return 1
            ;;
    esac
}

apt_fast_package_manager="${APT_FAST_PACKAGE_MANAGER:-}"

if [[ -n "$apt_fast_package_manager" ]]; then
    if ! resolve_apt_fast_package_manager "$apt_fast_package_manager"; then
        tlog_warn "$tag" "Fallback to interactive session: invalid APT_FAST_PACKAGE_MANAGER value."
        __ask_apt_fast_package_manager || exit $?
    fi
else
    __ask_apt_fast_package_manager || exit $?
fi

apt_fast_max_connection="${APT_FAST_MAX_CONNECTION:-}"

if [[ -n "$apt_fast_max_connection" ]]; then
    if ! resolve_apt_fast_max_connection "$apt_fast_max_connection"; then
        tlog_warn "$tag" "Fallback to interactive session: invalid APT_FAST_MAX_CONNECTION value."
        __ask_apt_fast_max_connection || exit $?
    fi
else
    __ask_apt_fast_max_connection || exit $?
fi

apt_fast_suppress_confirm_dialog="${APT_FAST_SUPPRESS_CONFIRM_DIALOG:-}"

if [[ -n "$apt_fast_suppress_confirm_dialog" ]]; then
    if ! resolve_apt_fast_suppress_confirm_dialog "$apt_fast_suppress_confirm_dialog"; then
        tlog_warn "$tag" "Fallback to interactive session: invalid APT_FAST_SUPPRESS_CONFIRM_DIALOG value."
        __ask_apt_fast_suppress_confirm_dialog || exit $?
    fi
else
    __ask_apt_fast_suppress_confirm_dialog || exit $?
fi

save_states "$CANONICAL_ID"
