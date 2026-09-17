#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_VSCODE_RESOLVER_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_VSCODE_RESOLVER_LOADED=1

source "$LIB_COMMON/common.sh"
source "$LIB_INSTALLER/state.sh"

##
# resolve_vscode_channel <channel>
#
# Resolves the VS Code package based on the selected release channel.
#
# Parameters:
#   channel - VS Code channel (stable, insiders, code, or code-insiders).
#
# Return:
#   0 - Channel and package selection resolved successfully.
#   1 - Channel value is invalid.
#
resolve_vscode_channel() {
    local channel="$1"
    local tag="channel-resolver:$CANONICAL_ID"
    local package

    case "${channel,,}" in
        code | stable)
            channel="stable"
            package="code"
            ;;
        code-insiders | insiders)
            channel="insiders"
            package="code-insiders"
            ;;
        *)
            tlog_error "$tag" \
                "Invalid VSCODE_CHANNEL value: %s. Expected stable, insiders, code, or code-insiders." \
                "$channel"

            return 1
            ;;
    esac

    set_state "VSCODE_CHANNEL" "$channel"
    set_state "VSCODE_PACKAGE" "$package"
    tlog_info "$tag" "Selected VSCode channel: %s (package: %s)" "$channel" "$package"
}
