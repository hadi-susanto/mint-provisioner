#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_UI_TOOLKIT_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_UI_TOOLKIT_LOADED=1

source "$LIB_COMMON/common.sh"

__ui_toolkit_has_library() {
    local pattern="$1"
    local libraries

    libraries="$(ldconfig -p 2>/dev/null)" || return 1
    grep -E "$pattern" <<< "$libraries" >/dev/null
}

__ui_toolkit_available() {
    case "$1" in
        gtk2) __ui_toolkit_has_library 'libgtk-x11-2\.0\.so' ;;
        gtk3) __ui_toolkit_has_library 'libgtk-3\.so' ;;
        gtk4) __ui_toolkit_has_library 'libgtk-4\.so' ;;
        qt5) __ui_toolkit_has_library 'libQt5Core\.so' ;;
        qt6) __ui_toolkit_has_library 'libQt6Core\.so' ;;
        *) return 1 ;;
    esac
}

##
# detect_ui_toolkit
#
# Detects the preferred installed GTK or Qt toolkit. KDE and Plasma prefer Qt;
# other desktops prefer GTK.
#
# Output:
#   Prints gtk2, gtk3, gtk4, qt5, or qt6 to standard output.
#
# Return:
#   0 - A supported UI toolkit was detected.
#   1 - No supported UI toolkit was detected.
#
detect_ui_toolkit() {
    local desktop="${XDG_CURRENT_DESKTOP:-}"
    local toolkit
    local -a preferred_toolkits=()

    if [[ "${desktop,,}" == *kde* || "${desktop,,}" == *plasma* ]]; then
        preferred_toolkits=(qt6 qt5 gtk4 gtk3 gtk2)
    else
        preferred_toolkits=(gtk4 gtk3 gtk2 qt6 qt5)
    fi

    for toolkit in "${preferred_toolkits[@]}"; do
        if __ui_toolkit_available "$toolkit"; then
            printf '%s\n' "$toolkit"

            return 0
        fi
    done

    tlog_warn "ui-toolkit" "No supported UI toolkit was detected"

    return 1
}
