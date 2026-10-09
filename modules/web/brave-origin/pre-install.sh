#!/usr/bin/env bash
set -euo pipefail

source "${LIB_INSTALLER}/apt.sh"
source "${LIB_INSTALLER}/state.sh"

load_states "$CANONICAL_ID" || exit $?
channel="$(get_state "BRAVE_ORIGIN_CHANNEL")" || exit $?

case "$channel" in
    release)
        key_url="https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg"
        repository_url="https://brave-browser-apt-release.s3.brave.com/"
        ;;

    beta)
        key_url="https://brave-browser-apt-beta.s3.brave.com/brave-browser-beta-archive-keyring.gpg"
        repository_url="https://brave-browser-apt-beta.s3.brave.com/"
        ;;

    nightly)
        key_url="https://brave-browser-apt-nightly.s3.brave.com/brave-browser-nightly-archive-keyring.gpg"
        repository_url="https://brave-browser-apt-nightly.s3.brave.com/"
        ;;

    *)
        tlog_error "pre-install:$CANONICAL_ID" "Invalid repository channel: $channel"

        exit 1
        ;;
esac

filename="brave-${channel}"
install_asc_key \
    "$CANONICAL_ID" \
    "$key_url" \
    "$repository_url" \
    "stable" \
    "main" \
    "$filename"
