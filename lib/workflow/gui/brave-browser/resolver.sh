#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_BRAVE_BROWSER_RESOLVER_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_BRAVE_BROWSER_RESOLVER_LOADED=1

source "$LIB_COMMON/common.sh"
source "$LIB_INSTALLER/state.sh"

##
# resolve_brave_browser_channel <channel>
#
# Resolves the Brave Browser package based on the selected release channel.
#
# Parameters:
#   channel - Brave Browser channel (release, stable, beta, or nightly).
#
# Return:
#   0 - Channel and package selection resolved successfully.
#   1 - Channel value is invalid.
#
resolve_brave_browser_channel() {
    local channel="$1"
    local tag="channel-resolver:$CANONICAL_ID"
    local package

    case "${channel,,}" in
        release | stable)
            channel="release"
            package="brave-browser"
            ;;
        beta)
            channel="beta"
            package="brave-browser-beta"
            ;;
        nightly)
            channel="nightly"
            package="brave-browser-nightly"
            ;;
        *)
            tlog_error "$tag" \
                "Invalid Brave Browser channel value: %s. Expected release, stable, beta, or nightly." \
                "$channel"

            return 1
            ;;
    esac

    set_state "BRAVE_BROWSER_CHANNEL" "$channel"
    set_state "BRAVE_BROWSER_PACKAGE" "$package"
    tlog_info "$tag" "Brave Origion channel: %s (package: %s)" "$channel" "$package"
}
