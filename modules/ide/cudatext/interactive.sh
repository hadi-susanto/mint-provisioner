#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/$CANONICAL_ID/resolver.sh"

cudatext_ui_toolkit="${CUDATEXT_UI_TOOLKIT:-}"
tag="interactive:$CANONICAL_ID"

if [[ -n "$cudatext_ui_toolkit" ]]; then
    if resolve_cudatext_ui_toolkit "$cudatext_ui_toolkit"; then
        save_states "$CANONICAL_ID" || exit $?

        exit 0
    fi

    tlog_warn "$tag" "Fallback to interactive session: invalid CUDATEXT_UI_TOOLKIT value."
fi

source "${LIB_INSTALLER}/prompt.sh"

if detected_toolkit="$(detect_ui_toolkit)"; then
    message="Detected '$detected_toolkit' UI toolkit on your system.
The matching CudaText package is recommended to reduce dependencies.
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
        resolve_cudatext_ui_toolkit "gtk2"
        ;;
    1)
        resolve_cudatext_ui_toolkit "gtk3"
        ;;
    2)
        resolve_cudatext_ui_toolkit "qt5"
        ;;
    3)
        resolve_cudatext_ui_toolkit "qt6"
        ;;
    *)
        tlog_error "$tag" "Unexpected UI toolkit selection index: %s" "$selected_index"

        return 1
        ;;
esac

save_states "$CANONICAL_ID"
