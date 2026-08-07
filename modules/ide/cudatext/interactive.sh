#!/usr/bin/env bash
set -euo pipefail

source "${LIB_COMMON}/common.sh"
source "${LIB_INSTALLER}/state.sh"
source "${LIB_INSTALLER}/ui-toolkit.sh"

__resolve_cudatext_ui_toolkit() {
    local toolkit="${1:-auto}"

    if [[ "$toolkit" == "auto" ]]; then
        if ! toolkit="$(detect_ui_toolkit)"; then
            tlog_error "$CANONICAL_ID" "UI toolkit auto-detection failed"

            return 1
        fi

        tlog_info "$CANONICAL_ID" "Detected UI toolkit: %s" "$toolkit"
        tlog_info "$CANONICAL_ID" "Recommending the matching CudaText $toolkit package"
    fi

    case "$toolkit" in
        gtk4)
            tlog_info "$CANONICAL_ID" "gtk4 installed in the system, using gtk3 as fallback"
            toolkit="gtk3"
            ;;

        gtk2|gtk3|qt5|qt6)
            ;;

        *)
            tlog_error "$CANONICAL_ID" \
                "Invalid UI toolkit: $toolkit. Expected auto, gtk2, gtk3, qt5, or qt6."

            return 1
            ;;
    esac

    set_state "CUDATEXT_UI_TOOLKIT" "$toolkit"
    tlog_info "$CANONICAL_ID" "Selected CudaText UI toolkit: %s" "$toolkit"
}

if [[ "${CUDATEXT_NON_INTERACTIVE:-${NON_INTERACTIVE:-false}}" == "true" ]]; then
    if ! __resolve_cudatext_ui_toolkit "${CUDATEXT_UI_TOOLKIT:-auto}"; then
        tlog_error "$CANONICAL_ID" \
            "Failed to resolve the CudaText UI toolkit. Specify CUDATEXT_UI_TOOLKIT manually."

        exit 1
    fi

    save_states "$CANONICAL_ID" || exit $?

    exit 0
fi

source "${LIB_INSTALLER}/prompt.sh"

__ask_cudatext_ui_toolkit() {
    local detected_toolkit
    local message
    local selected_index
    local toolkit

    if detected_toolkit="$(detect_ui_toolkit)"; then
        message="Detected the '$detected_toolkit' UI toolkit on your system.

The matching CudaText '$detected_toolkit' package is recommended because it can reduce additional dependencies.

Which UI toolkit do you want to use for CudaText?"
    else
        message="UI toolkit auto-detection failed.

Please choose the UI toolkit you want to use for CudaText."
    fi

    selected_index="$(
        choose_option \
            "$message" \
            "GTK 2" \
            "GTK 3" \
            "Qt 5" \
            "Qt 6"
    )" || return $?

    case "$selected_index" in
        0)
            toolkit="gtk2"
            ;;
        1)
            toolkit="gtk3"
            ;;
        2)
            toolkit="qt5"
            ;;
        3)
            toolkit="qt6"
            ;;
        *)
            log_error "[$CANONICAL_ID] Unexpected UI toolkit selection index: $selected_index"

            return 1
            ;;
    esac

    __resolve_cudatext_ui_toolkit "$toolkit"
}

if [[ -n "${CUDATEXT_UI_TOOLKIT:-}" ]]; then
    __resolve_cudatext_ui_toolkit "$CUDATEXT_UI_TOOLKIT" || exit $?
else
    __ask_cudatext_ui_toolkit || exit $?
fi

save_states "$CANONICAL_ID" || exit $?

exit 0
