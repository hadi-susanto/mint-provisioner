#!/usr/bin/env bash
set -euo pipefail

source "${LIB_DIR}/common.sh"
source "${LIB_DIR}/state.sh"

__resolve_mkvtoolnix_gui_enabled() {
    local gui_enabled="${1:-}"

    case "${gui_enabled,,}" in
        true)
            set_state "MKVTOOLNIX_GUI_ENABLED" "true"
            set_state "MKVTOOLNIX_PACKAGE" "mkvtoolnix-gui"
            ;;
        false)
            set_state "MKVTOOLNIX_GUI_ENABLED" "false"
            set_state "MKVTOOLNIX_PACKAGE" "mkvtoolnix"
            ;;
        *)
            log_error \
                "[$CANONICAL_ID] Invalid MKVTOOLNIX_GUI_ENABLED value: $gui_enabled. Expected true or false."

            return 1
            ;;
    esac

    return 0
}

if [[ "${MKVTOOLNIX_NON_INTERACTIVE:-${NON_INTERACTIVE:-false}}" == "true" ]]; then
    __resolve_mkvtoolnix_gui_enabled \
        "${MKVTOOLNIX_GUI_ENABLED:-false}" || exit $?

    save_states "$CANONICAL_ID" || exit $?

    exit 0
fi

source "${LIB_DIR}/prompt.sh"

__ask_mkvtoolnix_gui_enabled() {
    local selected_index

    selected_index="$(
        choose_option \
            "Install MKVToolNix GUI alongside the CLI?" \
            "Yes, install the GUI" \
            "No, install CLI tools only"
    )" || return $?

    case "$selected_index" in
        0)
            __resolve_mkvtoolnix_gui_enabled "true"
            ;;
        1)
            __resolve_mkvtoolnix_gui_enabled "false"
            ;;
        *)
            log_error \
                "[$CANONICAL_ID] Unexpected MKVToolNix selection index: $selected_index"

            return 1
            ;;
    esac
}

if [[ -n "${MKVTOOLNIX_GUI_ENABLED:-}" ]]; then
    __resolve_mkvtoolnix_gui_enabled \
        "$MKVTOOLNIX_GUI_ENABLED" || exit $?
else
    __ask_mkvtoolnix_gui_enabled || exit $?
fi

save_states "$CANONICAL_ID" || exit $?

exit 0
