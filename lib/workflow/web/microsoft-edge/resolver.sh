#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_MICROSOFT_EDGE_RESOLVER_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_MICROSOFT_EDGE_RESOLVER_LOADED=1

source "$LIB_COMMON/common.sh"
source "$LIB_INSTALLER/state.sh"

##
# resolve_microsoft_edge_channel <channel>
#
# Resolves Microsoft Edge channel and package states.
#
# Parameters:
#   channel    Supported value: stable, beta, dev, canary.
#
# Return:
#   1 when channel value is invalid.
#
resolve_microsoft_edge_channel() {
    local channel="$1"
    local tag="channel-resolver:$CANONICAL_ID"
    local package

    case "${channel,,}" in
        stable)
            channel="stable"
            package="microsoft-edge-stable"
            ;;
        beta)
            channel="beta"
            package="microsoft-edge-beta"
            ;;
        dev)
            channel="dev"
            package="microsoft-edge-dev"
            ;;
        canary)
            channel="canary"
            package="microsoft-edge-canary"
            ;;
        *)
            tlog_error "$tag" \
                "Invalid MICROSOFT_EDGE_CHANNEL value: %s. Expected stable, beta, dev, or canary." \
                "$channel"

            return 1
            ;;
    esac

    set_state "MICROSOFT_EDGE_CHANNEL" "$channel"
    set_state "MICROSOFT_EDGE_PACKAGE" "$package"
    tlog_info "$tag" "Selected Microsoft Edge channel: %s (package: %s)" "$channel" "$package"
}
