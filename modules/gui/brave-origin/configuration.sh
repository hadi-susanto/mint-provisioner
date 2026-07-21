#!/usr/bin/env bash
set -euo pipefail

source "${LIB_DIR}/common.sh"
source "${LIB_DIR}/state.sh"

__set_brave_origin_channel() {
    local channel="${1:-}"

    case "${channel,,}" in
        release | stable)
            set_state "BRAVE_ORIGIN_CHANNEL" "release"
            set_state "BRAVE_ORIGIN_PACKAGE" "brave-origin"
            ;;
        beta)
            set_state "BRAVE_ORIGIN_CHANNEL" "beta"
            set_state "BRAVE_ORIGIN_PACKAGE" "brave-origin-beta"
            ;;
        nightly)
            set_state "BRAVE_ORIGIN_CHANNEL" "nightly"
            set_state "BRAVE_ORIGIN_PACKAGE" "brave-origin-nightly"
            ;;
        *)
            log_error \
                "[$CANONICAL_ID] Invalid BRAVE_ORIGIN_CHANNEL value: $channel. Expected release, stable, beta, or nightly."

            return 1
            ;;
    esac

    return 0
}

if [[ "${BRAVE_ORIGIN_NON_INTERACTIVE:-${NON_INTERACTIVE:-false}}" == "true" ]]; then
    __set_brave_origin_channel \
        "${BRAVE_ORIGIN_CHANNEL:-release}" || exit $?

    save_states "$CANONICAL_ID" || exit $?

    exit 0
fi

source "${LIB_DIR}/prompt.sh"

__ask_brave_origin_channel() {
    local selected_index

    selected_index="$(
        choose_option \
            "Which Brave Origin channel do you want to install?" \
            "Release (recommended)" \
            "Beta" \
            "Nightly"
    )" || return $?

    case "$selected_index" in
        0)
            __set_brave_origin_channel "release"
            ;;
        1)
            __set_brave_origin_channel "beta"
            ;;
        2)
            __set_brave_origin_channel "nightly"
            ;;
        *)
            log_error \
                "[$CANONICAL_ID] Unexpected Brave Origin channel index: $selected_index"

            return 1
            ;;
    esac
}

if [[ -n "${BRAVE_ORIGIN_CHANNEL:-}" ]]; then
    __set_brave_origin_channel "$BRAVE_ORIGIN_CHANNEL" || exit $?
else
    __ask_brave_origin_channel || exit $?
fi

save_states "$CANONICAL_ID" || exit $?

exit 0
