#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_BRAVE_ORIGIN_RESOLVER_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_BRAVE_ORIGIN_RESOLVER_LOADED=1

source "$LIB_COMMON/common.sh"
source "$LIB_INSTALLER/state.sh"

##
# resolve_brave_origin_channel <channel>
#
# Resolves the Brave Origin package based on the selected release channel.
#
# Parameters:
#   channel - Brave Origin channel (release, stable, beta, or nightly).
#
# Return:
#   0 - Channel and package selection resolved successfully.
#   1 - Channel value is invalid.
#
resolve_brave_origin_channel() {
    local channel="$1"
    local tag="channel-resolver:$CANONICAL_ID"
    local package

    case "${channel,,}" in
        release | stable)
            channel="release"
            package="brave-origin"
            ;;
        beta)
            channel="beta"
            package="brave-origin-beta"
            ;;
        nightly)
            channel="nightly"
            package="brave-origin-nightly"
            ;;
        *)
            tlog_error "$tag" \
                "Invalid Brave Origin channel value: %s. Expected release, stable, beta, or nightly." \
                "$channel"

            return 1
            ;;
    esac

    set_state "BRAVE_ORIGIN_CHANNEL" "$channel"
    set_state "BRAVE_ORIGIN_PACKAGE" "$package"
    tlog_info "$tag" "Brave Origion channel: %s (package: %s)" "$channel" "$package"
}