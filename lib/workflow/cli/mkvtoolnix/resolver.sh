#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_MKVTOOLNIX_RESOLVER_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_MKVTOOLNIX_RESOLVER_LOADED=1

source "$LIB_COMMON/common.sh"
source "$LIB_INSTALLER/state.sh"

##
# resolve_mkvtoolnix_gui_enabled <gui_enabled>
#
# Resolves the MKVToolNix package based on whether the GUI is enabled.
#
# Parameters:
#   gui_enabled - Whether the MKVToolNix GUI is enabled (true/false).
#
# Return:
#   0 - Package selection resolved successfully.
#   1 - GUI enabled value is invalid.
#
resolve_mkvtoolnix_gui_enabled() {
    local gui_enabled="$1"
    local tag="gui-resolver:$CANONICAL_ID"

    case "${gui_enabled,,}" in
        true)
            set_state "MKVTOOLNIX_PACKAGE" "mkvtoolnix-gui"
            tlog_info "$tag" "Mark MKVToolNix CLI and GUI for installation (mkvtoolnix-gui)"
            ;;
        false)
            set_state "MKVTOOLNIX_PACKAGE" "mkvtoolnix"
            tlog_info "$tag" "Mark MKVToolNix CLI for installation (mkvtoolnix)"
            ;;
        *)
            tlog_error "$tag" \
                "Invalid MKVToolNix GUI enabled value: %s. Expected true or false." \
                "$gui_enabled"

            return 1
            ;;
    esac
}
