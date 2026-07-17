#!/usr/bin/env bash

source "${LIB_DIR}/common.sh"
source "${LIB_DIR}/state.sh"
source "${LIB_DIR}/prompt.sh"
source "${MODULES_DIR}/${CANONICAL_ID}/helper.sh"

##
# Resolves the Double Commander package variant.
#
# Uses DOUBLE_COMMANDER_UI_TOOLKIT when explicitly configured. When unset or
# set to "auto", the toolkit is detected automatically.
#
# Output:
#   Prints one of:
#   doublecmd-gtk, doublecmd-qt, or doublecmd-qt6.
#
# Returns:
#   0 - Package variant was resolved.
#   1 - Invalid toolkit value.
#   Any non-zero status returned by auto_detect_ui_toolkit.
#
__detect_double_commander_ui_toolkit() {
    local toolkit="${1:-}"

    if [[ "$toolkit" == "auto" ]]; then
        toolkit="$(auto_detect_ui_toolkit)" || return $?
    fi

    case "$toolkit" in
        gtk)
            printf '%s\n' "doublecmd-gtk"
            ;;

        qt|qt5)
            printf '%s\n' "doublecmd-qt"
            ;;

        qt6)
            printf '%s\n' "doublecmd-qt6"
            ;;

        *)
            log_error \
                "[$CANONICAL_ID] Invalid UI toolkit: $toolkit. Expected auto, gtk, qt, qt5, or qt6."

            return 1
            ;;
    esac

    return 0
}

if [[ "${DOUBLE_COMMANDER_NON_INTERACTIVE-${NON_INTERACTIVE:-false}}" == "true" ]]; then
    UI_TOOLKIT="$(__detect_double_commander_ui_toolkit "${DOUBLE_COMMANDER_UI_TOOLKIT:-auto}")" || {
        log_error \
            "[$CANONICAL_ID] Auto detection failed. Please specify DOUBLE_COMMANDER_UI_TOOLKIT manually. Accepted values: auto, gtk, qt, qt5, qt6."

        exit 1
    }

    set_state \
        "DOUBLE_COMMANDER_PACKAGE" \
        "$UI_TOOLKIT"

    save_states "$CANONICAL_ID" || exit $?

    exit 0
fi

##
# Asks the user which Double Commander UI toolkit should be installed.
#
# Stores the selected toolkit in the DOUBLE_COMMANDER_UI_TOOLKIT state.
#
# Returns:
#   0 - Toolkit was selected and stored.
#   Any non-zero status returned by choose_option or set_state.
#
__ask_double_commander_ui_toolkit() {
    local selected_index
    local message
    local ui_toolkit
    local package

    if ui_toolkit="$(auto_detect_ui_toolkit)"; then
        message="Detected the '$ui_toolkit' UI toolkit on your system.

Installing Double Commander with a matching UI toolkit is preferable because it can reduce additional dependencies.

Which UI toolkit do you want to use for Double Commander?"
    else
        message="UI toolkit auto-detection failed.

Please manually choose the UI toolkit you want to use for Double Commander."
    fi

    selected_index="$(
        choose_option \
            "$message" \
            "GTK (doublecmd-gtk)" \
            "Qt 5 (doublecmd-qt)" \
            "Qt 6 (doublecmd-qt6)"
    )" || return $?

    case "$selected_index" in
        0)
            package="doublecmd-gtk"
            ;;

        1)
            package="doublecmd-qt"
            ;;

        2)
            package="doublecmd-qt6"
            ;;

        *)
            log_error \
                "[$CANONICAL_ID] Unexpected UI toolkit selection index: $selected_index"

            return 1
            ;;
    esac

    set_state \
        "DOUBLE_COMMANDER_PACKAGE" "$package"

    return 0
}

if [[ -n "${DOUBLE_COMMANDER_UI_TOOLKIT:-}" ]]; then
    UI_TOOLKIT="$(__detect_double_commander_ui_toolkit "$DOUBLE_COMMANDER_UI_TOOLKIT")" || {
        log_error \
            "[$CANONICAL_ID] Invalid value for DOUBLE_COMMANDER_UI_TOOLKIT. Accepted values: auto, gtk, qt, qt5, qt6."

        exit $?
    }

    set_state \
        "DOUBLE_COMMANDER_PACKAGE" \
        "$UI_TOOLKIT"
else
    __ask_double_commander_ui_toolkit || exit $?
fi

save_states "$CANONICAL_ID" || exit $?

exit 0