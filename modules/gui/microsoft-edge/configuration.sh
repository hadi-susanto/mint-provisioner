#!/usr/bin/env bash

source "${LIB_DIR}/common.sh"
source "${LIB_DIR}/state.sh"

__resolve_microsoft_edge_channel() {
    case "${1,,}" in
        stable)
            set_state "MICROSOFT_EDGE_CHANNEL" "stable"
            set_state "MICROSOFT_EDGE_PACKAGE" "microsoft-edge-stable"
            ;;
        beta)
            set_state "MICROSOFT_EDGE_CHANNEL" "beta"
            set_state "MICROSOFT_EDGE_PACKAGE" "microsoft-edge-beta"
            ;;
        dev)
            set_state "MICROSOFT_EDGE_CHANNEL" "dev"
            set_state "MICROSOFT_EDGE_PACKAGE" "microsoft-edge-dev"
            ;;
        canary)
            set_state "MICROSOFT_EDGE_CHANNEL" "canary"
            set_state "MICROSOFT_EDGE_PACKAGE" "microsoft-edge-canary"
            ;;
        *)
            log_error "Invalid MICROSOFT_EDGE_CHANNEL value: $1"
            log_error "Supported values: stable, beta, dev, canary"

            return 1
            ;;
    esac

    return 0
}

if [[ "${MICROSOFT_EDGE_NON_INTERACTIVE:-${NON_INTERACTIVE:-false}}" == "true" ]]; then
    __resolve_microsoft_edge_channel \
        "${MICROSOFT_EDGE_CHANNEL:-stable}" || exit $?

    save_states "$CANONICAL_ID" || exit $?

    exit 0
fi

source "${LIB_DIR}/prompt.sh"

__ask_microsoft_edge_channel() {
    local selected_index

    selected_index="$(
        choose_option \
            "Which Microsoft Edge channel do you want to install?" \
            "Stable (recommended)" \
            "Beta" \
            "Dev" \
            "Canary"
    )" || return $?

    case "$selected_index" in
        0) __resolve_microsoft_edge_channel "stable" ;;
        1) __resolve_microsoft_edge_channel "beta" ;;
        2) __resolve_microsoft_edge_channel "dev" ;;
        3) __resolve_microsoft_edge_channel "canary" ;;
    esac
}

if [[ -n "${MICROSOFT_EDGE_CHANNEL:-}" ]]; then
    __resolve_microsoft_edge_channel \
        "$MICROSOFT_EDGE_CHANNEL" || exit $?
else
    __ask_microsoft_edge_channel || exit $?
fi

save_states "$CANONICAL_ID" || exit $?

exit 0
