#!/usr/bin/env bash

#
# Prevent the library from being loaded more than once.
#
if (( ${__UI_TOOLKIT_LIB_LOADED:-0} )); then
    return 0
fi

readonly __UI_TOOLKIT_LIB_LOADED=1

__has_ui_toolkit_library() {
    local pattern="$1"
    local libraries

    libraries="$(ldconfig -p 2>/dev/null)" || return 1
    grep -E "$pattern" <<<"$libraries" >/dev/null
}

##
# Returns success when the GTK 2 shared library is available.
#
has_gtk2() {
    __has_ui_toolkit_library 'libgtk-x11-2\.0\.so'
}

##
# Returns success when the GTK 3 shared library is available.
#
has_gtk3() {
    __has_ui_toolkit_library 'libgtk-3\.so'
}

##
# Returns success when the GTK 4 shared library is available.
#
has_gtk4() {
    __has_ui_toolkit_library 'libgtk-4\.so'
}

##
# Returns success when the Qt 5 Core shared library is available.
#
has_qt5() {
    __has_ui_toolkit_library 'libQt5Core\.so'
}

##
# Returns success when the Qt 6 Core shared library is available.
#
has_qt6() {
    __has_ui_toolkit_library 'libQt6Core\.so'
}

##
# Detects an installed GTK or Qt toolkit variant.
#
# KDE Plasma desktops prefer Qt in this order:
#   qt6, qt5, gtk4, gtk3, gtk2
#
# Other desktops prefer:
#   gtk4, gtk3, gtk2, qt6, qt5
#
# Output:
#   Prints one of: gtk2, gtk3, gtk4, qt5, or qt6.
#
# Returns:
#   1 when no supported UI toolkit is detected.
#
detect_ui_toolkit() {
    local desktop="${XDG_CURRENT_DESKTOP:-}"
    local -a preferred_toolkits=()

    if [[ "${desktop,,}" == *kde* ||
          "${desktop,,}" == *plasma* ]]; then
        preferred_toolkits=(qt6 qt5 gtk4 gtk3 gtk2)
    else
        preferred_toolkits=(gtk4 gtk3 gtk2 qt6 qt5)
    fi

    local toolkit

    for toolkit in "${preferred_toolkits[@]}"; do
        if "has_${toolkit}"; then
            printf '%s\n' "$toolkit"

            return 0
        fi
    done

    return 1
}
