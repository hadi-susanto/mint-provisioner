#!/usr/bin/env bash

##
# Returns success when a GTK 3 or GTK 4 shared library is available.
#
has_gtk() {
    ldconfig -p 2>/dev/null |
        grep -qE 'libgtk-(3|4)\.so'
}

##
# Returns success when the Qt 5 Core shared library is available.
#
has_qt5() {
    ldconfig -p 2>/dev/null |
        grep -q 'libQt5Core\.so'
}

##
# Returns success when the Qt 6 Core shared library is available.
#
has_qt6() {
    ldconfig -p 2>/dev/null |
        grep -q 'libQt6Core\.so'
}

##
# Automatically selects an available UI toolkit.
#
# KDE Plasma desktops prefer Qt in this order:
#   qt6, qt5, gtk
#
# Other desktops prefer:
#   gtk, qt6, qt5
#
# Output:
#   Prints one of: gtk, qt6, or qt5.
#
# Returns:
#   0 - An available UI toolkit was detected.
#   1 - No supported UI toolkit was detected.
#
auto_detect_ui_toolkit() {
    local desktop="${XDG_CURRENT_DESKTOP:-}"
    local -a preferred_toolkits=()

    if [[ "${desktop,,}" == *kde* ||
          "${desktop,,}" == *plasma* ]]; then
        preferred_toolkits=(qt6 qt5 gtk)
    else
        preferred_toolkits=(gtk qt6 qt5)
    fi

    local toolkit

    for toolkit in "${preferred_toolkits[@]}"; do
        case "$toolkit" in
            gtk)
                if has_gtk; then
                    printf '%s\n' "$toolkit"

                    return 0
                fi
                ;;

            qt6)
                if has_qt6; then
                    printf '%s\n' "$toolkit"

                    return 0
                fi
                ;;

            qt5)
                if has_qt5; then
                    printf '%s\n' "$toolkit"

                    return 0
                fi
                ;;
        esac
    done

    return 1
}
