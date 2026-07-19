#!/usr/bin/env bash

source "${LIB_DIR}/common.sh"
source "${LIB_DIR}/state.sh"

__resolve_mkvtoolnix_gui_enabled() {
    case "${1,,}" in
        true)
            set_state "MKVTOOLNIX_GUI_ENABLED" "true"
            set_state "MKVTOOLNIX_PACKAGE" "mkvtoolnix-gui"
            ;;
        false)
            set_state "MKVTOOLNIX_GUI_ENABLED" "false"
            set_state "MKVTOOLNIX_PACKAGE" "mkvtoolnix"
            ;;
        *)
            log_error "Invalid MKVTOOLNIX_GUI_ENABLED value: $1"
            log_error "Supported values: true, false"

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

    if ((selected_index == 0)); then
        __resolve_mkvtoolnix_gui_enabled "true"

        return $?
    fi

    __resolve_mkvtoolnix_gui_enabled "false"
}

if [[ -n "${MKVTOOLNIX_GUI_ENABLED:-}" ]]; then
    __resolve_mkvtoolnix_gui_enabled \
        "$MKVTOOLNIX_GUI_ENABLED" || exit $?
else
    __ask_mkvtoolnix_gui_enabled || exit $?
fi

save_states "$CANONICAL_ID" || exit $?

exit 0
