#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/$CANONICAL_ID/resolver.sh"

double_commander_ui_toolkit="${DOUBLE_COMMANDER_UI_TOOLKIT:-}"
tag="interactive:$CANONICAL_ID"

if [[ -n "$double_commander_ui_toolkit" ]]; then
    if resolve_double_commander_package "$double_commander_ui_toolkit"; then
        save_states "$CANONICAL_ID" || exit $?

        exit 0
    fi

    tlog_warn "$tag" "Fallback to interactive session: invalid DOUBLE_COMMANDER_UI_TOOLKIT value."
fi

source "${LIB_INSTALLER}/prompt.sh"

if detected_toolkit="$(detect_ui_toolkit)"; then
    message="Detected '$detected_toolkit' UI toolkit on your system.
Using a matching UI toolkit can reduce additional dependencies.
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
)" || exit $?

case "$selected_index" in
    0)
        resolve_double_commander_package "gtk"
        ;;
    1)
        resolve_double_commander_package "qt5"
        ;;
    2)
        resolve_double_commander_package "qt6"
        ;;
    *)
        tlog_error "$tag" "Unexpected UI toolkit selection index: $selected_index"

        exit 1
        ;;
esac

save_states "$CANONICAL_ID"
