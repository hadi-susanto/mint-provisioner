#!/usr/bin/env bash
set -euo pipefail

source "${LIB_INSTALLER}/apt.sh"
source "${LIB_INSTALLER}/messages.sh"

if ! apt_install "$CANONICAL_ID" "firefoxpwa"; then
    log_error "[$CANONICAL_ID] Failed to install firefoxpwa"

    exit 1
fi

add_message "$CANONICAL_ID" "info" \
    "Install the PWAsForFirefox browser extension in Firefox, then run 'firefoxpwa runtime install' if no system Firefox is used."
