#!/usr/bin/env bash
set -euo pipefail

source "${LIB_DIR}/common.sh"
source "${LIB_DIR}/state.sh"
source "${MODULES_DIR}/${CANONICAL_ID}/helper.sh"

##
# Resolves a Double Commander UI toolkit to its package name.
#
# Arguments:
#   $1 - Toolkit: auto, gtk, qt, qt5, or qt6. Defaults to auto.
#
# State:
#   Stores the selected package as DOUBLE_COMMANDER_PACKAGE.
#
# Returns:
#   0 - Package resolved successfully.
#   1 - Invalid toolkit or auto-detection failed.
#
__resolve_double_commander_package() {
    local toolkit="${1:-auto}"
    local package

    if [[ "$toolkit" == "auto" ]]; then
        toolkit="$(auto_detect_ui_toolkit)" || return $?
    fi

    case "$toolkit" in
        gtk)
            package="doublecmd-gtk"
            ;;

        qt|qt5)
            package="doublecmd-qt"
            ;;

        qt6)
            package="doublecmd-qt6"
            ;;

        *)
            log_error \
                "[$CANONICAL_ID] Invalid UI toolkit: $toolkit. Expected auto, gtk, qt, qt5, or qt6."

            return 1
            ;;
    esac

    set_state "DOUBLE_COMMANDER_PACKAGE" "$package"
    log_info "[$CANONICAL_ID] Selected package: $package"
}

if [[ "${DOUBLE_COMMANDER_NON_INTERACTIVE:-${NON_INTERACTIVE:-false}}" == "true" ]]; then
    if ! __resolve_double_commander_package \
        "${DOUBLE_COMMANDER_UI_TOOLKIT:-auto}"
    then
        log_error \
            "[$CANONICAL_ID] Failed to resolve the Double Commander package. Specify DOUBLE_COMMANDER_UI_TOOLKIT manually."

        exit 1
    fi

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
    local selected_index
    local toolkit

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
            toolkit="gtk"
            ;;
        1)
            toolkit="qt5"
            ;;
        2)
            toolkit="qt6"
            ;;
        *)
            log_error \
                "[$CANONICAL_ID] Unexpected UI toolkit selection index: $selected_index"

            return 1
            ;;
    esac

    __resolve_double_commander_package "$toolkit"
}

if [[ -n "${DOUBLE_COMMANDER_UI_TOOLKIT:-}" ]]; then
    __resolve_double_commander_package \
        "$DOUBLE_COMMANDER_UI_TOOLKIT" || exit $?
else
    __ask_double_commander_ui_toolkit || exit $?
fi

save_states "$CANONICAL_ID" || exit $?

exit 0
