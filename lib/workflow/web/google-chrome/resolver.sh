#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_GOOGLE_CHROME_RESOLVER_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_GOOGLE_CHROME_RESOLVER_LOADED=1

source "$LIB_COMMON/common.sh"
source "$LIB_INSTALLER/state.sh"

##
# resolve_google_chrome_channel <channel>
#
# Resolves Google Chrome channel and package states.
#
# Parameters:
#   channel    Supported value: stable, beta, unstable, canary.
#
# Return:
#   1 when channel value is invalid.
#
resolve_google_chrome_channel() {
    local channel="$1"
    local tag="channel-resolver:$CANONICAL_ID"
    local package

    case "${channel,,}" in
        stable)
            channel="stable"
            package="google-chrome-stable"
            ;;
        beta)
            channel="beta"
            package="google-chrome-beta"
            ;;
        unstable)
            channel="unstable"
            package="google-chrome-unstable"
            ;;
        canary)
            channel="canary"
            package="google-chrome-canary"
            ;;
        *)
            tlog_error "$tag" \
                "Invalid GOOGLE_CHROME_CHANNEL value: %s. Expected stable, beta, unstable, or canary." \
                "$channel"

            return 1
            ;;
    esac

    set_state "GOOGLE_CHROME_CHANNEL" "$channel"
    set_state "GOOGLE_CHROME_PACKAGE" "$package"
    tlog_info "$tag" "Selected Google Chrome channel: %s (package: %s)" "$channel" "$package"
}
