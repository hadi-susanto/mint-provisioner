#!/usr/bin/env bash
set -euo pipefail

source "${LIB_COMMON}/common.sh"
source "${LIB_INSTALLER}/state.sh"

__resolve_vscode_channel() {
    local channel="${1:-}"

    case "${channel,,}" in
        code | stable)
            set_state "VSCODE_CHANNEL" "stable"
            set_state "VSCODE_PACKAGE" "code"
            ;;
        code-insiders | insiders)
            set_state "VSCODE_CHANNEL" "insiders"
            set_state "VSCODE_PACKAGE" "code-insiders"
            ;;
        *)
            tlog_error \
                "$CANONICAL_ID" \
                "Invalid VSCODE_CHANNEL value: %s. Expected stable, insiders, code, or code-insiders." \
                "$channel"

            return 1
            ;;
    esac
}

if [[ "${VSCODE_NON_INTERACTIVE:-${NON_INTERACTIVE:-false}}" == "true" ]]; then
    __resolve_vscode_channel "${VSCODE_CHANNEL:-stable}" || exit $?
    save_states "$CANONICAL_ID" || exit $?

    exit 0
fi

source "${LIB_INSTALLER}/prompt.sh"

__ask_vscode_channel() {
    local selected_index

    selected_index="$(
        choose_option \
            "Which Visual Studio Code channel do you want to install?" \
            "Stable (code, recommended)" \
            "Insiders (code-insiders)"
    )" || return $?

    case "$selected_index" in
        0)
            __resolve_vscode_channel "stable"
            ;;
        1)
            __resolve_vscode_channel "insiders"
            ;;
        *)
            log_error \
                "[$CANONICAL_ID] Unexpected Visual Studio Code channel index: $selected_index"

            return 1
            ;;
    esac
}

if [[ -n "${VSCODE_CHANNEL:-}" ]]; then
    __resolve_vscode_channel "$VSCODE_CHANNEL" || exit $?
else
    __ask_vscode_channel || exit $?
fi

save_states "$CANONICAL_ID" || exit $?

exit 0
