#!/usr/bin/env bash
set -euo pipefail

source "${LIB_DIR}/common.sh"
source "${LIB_DIR}/state.sh"

__resolve_microsoft_edge_channel() {
    local channel="${1:-}"

    case "${channel,,}" in
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
            log_error \
                "[$CANONICAL_ID] Invalid MICROSOFT_EDGE_CHANNEL value: $channel. Expected stable, beta, dev, or canary."

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
        0)
            __resolve_microsoft_edge_channel "stable"
            ;;
        1)
            __resolve_microsoft_edge_channel "beta"
            ;;
        2)
            __resolve_microsoft_edge_channel "dev"
            ;;
        3)
            __resolve_microsoft_edge_channel "canary"
            ;;
        *)
            log_error \
                "[$CANONICAL_ID] Unexpected Microsoft Edge channel index: $selected_index"

            return 1
            ;;
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
