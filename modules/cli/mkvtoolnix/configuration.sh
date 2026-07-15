#!/usr/bin/env bash

source "${LIB_DIR}/common.sh"
source "${LIB_DIR}/state.sh"

if [[ "${NONINTERACTIVE:-false}" == "true" ]]; then
    set_state \
        "MKVTOOLNIX_GUI_ENABLED" \
        "${MKVTOOLNIX_GUI_ENABLED:-false}"

    save_states "$CANONICAL_ID" || exit $?

    exit 0
fi

source "${LIB_DIR}/prompt.sh"

__ask_mkvtoolnix_gui_enabled() {
    local selected_index

    selected_index="$(
        choose_option \
            "Do you want to install MkvToolNix GUI alongside with the CLI?" \
            "Yes, Install MkvToolNix GUI component" \
            "No, Just install CLI tools"
    )" || return $?

    if ((selected_index == 0)); then
        set_state "MKVTOOLNIX_GUI_ENABLED" "true"
    else
        set_state "MKVTOOLNIX_GUI_ENABLED" "false"
    fi

    return 0
}

if [[ -n "${MKVTOOLNIX_GUI_ENABLED:-}" ]]; then
    set_state "MKVTOOLNIX_GUI_ENABLED" "$MKVTOOLNIX_GUI_ENABLED"
else
    __ask_mkvtoolnix_gui_enabled || exit $?
fi

save_states "$CANONICAL_ID" || exit $?

exit 0
