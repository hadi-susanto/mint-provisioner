#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_CUDATEXT_RESOLVER_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_CUDATEXT_RESOLVER_LOADED=1

source "$LIB_COMMON/common.sh"
source "$LIB_INSTALLER/state.sh"
source "$LIB_INSTALLER/ui-toolkit.sh"

##
# resolve_cudatext_ui_toolkit <toolkit>
#
# Resolves the CudaText UI toolkit, including automatic toolkit detection
# and the gtk4-to-gtk3 fallback.
#
# Parameters:
#   toolkit - UI toolkit (auto, gtk2, gtk3, gtk4, qt5, or qt6).
#
# Return:
#   0 - UI toolkit resolved successfully.
#   1 - UI toolkit value is invalid.
#
resolve_cudatext_ui_toolkit() {
    local toolkit="$1"
    local tag="toolkit-resolver:$CANONICAL_ID"

    if [[ "$toolkit" == "auto" ]]; then
        toolkit="$(detect_ui_toolkit)" || return $?
    fi

    case "$toolkit" in
        gtk4)
            tlog_info "$tag" "gtk4 installed in the system, using gtk3 as fallback"
            toolkit="gtk3"
            ;;
        gtk2 | gtk3 | qt5 | qt6)
            ;;
        *)
            tlog_error "$tag" \
                "Invalid UI toolkit: %s. Expected auto, gtk2, gtk3, qt5, or qt6." \
                "$toolkit"

            return 1
            ;;
    esac

    set_state "CUDATEXT_UI_TOOLKIT" "$toolkit"
    tlog_info "$tag" "Selected CudaText UI toolkit: %s" "$toolkit"
}
