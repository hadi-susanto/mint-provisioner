#!/usr/bin/env bash

source "${LIB_DIR}/common.sh"
source "${LIB_DIR}/state.sh"
source "${MODULES_DIR}/${CANONICAL_ID}/helper.sh"

##
# Resolves a Double Commander UI toolkit to its package name.
#
# Arguments:
#   $1 - Toolkit: auto, gtk, qt, qt5, or qt6. Defaults to auto.
#
# Output:
#   doublecmd-gtk, doublecmd-qt, or doublecmd-qt6.
#
# Returns:
#   0 - Package resolved successfully.
#   1 - Invalid toolkit or auto-detection failed.
#
__resolve_double_commander_package() {
    local toolkit="${1:-auto}"

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

if [[ "${DOUBLE_COMMANDER_NON_INTERACTIVE:-${NON_INTERACTIVE:-false}}" == "true" ]]; then
    package="$(
        __resolve_double_commander_package \
            "${DOUBLE_COMMANDER_UI_TOOLKIT:-auto}"
    )" || {
        log_error \
            "[$CANONICAL_ID] Failed to resolve the Double Commander package. Specify DOUBLE_COMMANDER_UI_TOOLKIT manually."

        exit 1
    }

    set_state "DOUBLE_COMMANDER_PACKAGE" "$package"
    save_states "$CANONICAL_ID" || exit $?

    exit 0
fi

source "${LIB_DIR}/prompt.sh"

##
# Asks the user which Double Commander UI toolkit to install.
#
# Stores the selected package in DOUBLE_COMMANDER_PACKAGE.
#
# Returns:
#   0 - Package selected and stored.
#   1 - Selection failed or an unexpected index was returned.
#
__ask_double_commander_ui_toolkit() {
    local detected_toolkit
    local message
    local package
    local selected_index

    if detected_toolkit="$(auto_detect_ui_toolkit)"; then
        message="Detected the '$detected_toolkit' UI toolkit on your system.

Installing Double Commander with a matching UI toolkit can reduce additional dependencies.

Which UI toolkit do you want to use for Double Commander?"
    else
        message="UI toolkit auto-detection failed.

Please choose the UI toolkit you want to use for Double Commander."
    fi

    selected_index="$(
        choose_option \
            "$message" \
            "GTK — recommended for Cinnamon, MATE, and Xfce" \
            "Qt 5 — for Qt 5-based desktops" \
            "Qt 6 — for modern Qt 6-based desktops"
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

    set_state "DOUBLE_COMMANDER_PACKAGE" "$package"
}

if [[ -n "${DOUBLE_COMMANDER_UI_TOOLKIT:-}" ]]; then
    package="$(
        __resolve_double_commander_package \
            "$DOUBLE_COMMANDER_UI_TOOLKIT"
    )" || exit $?

    set_state "DOUBLE_COMMANDER_PACKAGE" "$package"
else
    __ask_double_commander_ui_toolkit || exit $?
fi

save_states "$CANONICAL_ID" || exit $?

exit 0
