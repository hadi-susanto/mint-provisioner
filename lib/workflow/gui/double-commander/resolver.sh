#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_DOUBLE_COMMANDER_RESOLVER_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_DOUBLE_COMMANDER_RESOLVER_LOADED=1

source "$LIB_COMMON/common.sh"
source "$LIB_INSTALLER/state.sh"
source "$LIB_INSTALLER/ui-toolkit.sh"

##
# resolve_double_commander_package <toolkit>
#
# Resolves the Double Commander package based on the selected UI toolkit.
# When the toolkit is set to auto, the toolkit is detected automatically.
#
# Parameters:
#   toolkit - UI toolkit (auto, gtk2, gtk3, gtk4, qt5, or qt6).
#
# Return:
#   0 - Package selection resolved successfully.
#   1 - UI toolkit value is invalid.
#
resolve_double_commander_package() {
    local toolkit="$1"
    local package=""
    local tag="package-resolver:$CANONICAL_ID"

    if [[ "$toolkit" == "auto" ]]; then
        toolkit="$(detect_ui_toolkit)" || return $?
    fi

    case "${toolkit,,}" in
        gtk4 | gtk3 | gtk2 | gtk)
            package="doublecmd-gtk"
            ;;
        qt5)
            package="doublecmd-qt"
            ;;
        qt6)
            package="doublecmd-qt6"
            ;;
        *)
            tlog_error "$tag" \
                "Invalid UI toolkit: %s. Expected auto, gtk2, gtk3, gtk4, qt5, or qt6." \
                "$toolkit"

            return 1
            ;;
    esac

    set_state "DOUBLE_COMMANDER_PACKAGE" "$package"
    tlog_info "$tag" "Selected Double Commander package: %s" "$package"
}
