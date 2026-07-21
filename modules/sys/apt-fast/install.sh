#!/usr/bin/env bash
set -euo pipefail

source "${LIB_DIR}/common.sh"
source "${LIB_DIR}/state.sh"

if ! load_states "$CANONICAL_ID"; then
    log_error "[$CANONICAL_ID] apt-fast installation state was not found"

    exit 1
fi

log_info "[$CANONICAL_ID] Preparing non-interactive apt-fast installation via debconf-set-selections"

APT_FAST_PACKAGE_MANAGER="$(get_state "APT_FAST_PACKAGE_MANAGER")" || exit 2
if [[ -z "$APT_FAST_PACKAGE_MANAGER" ]]; then
    log_error "APT_FAST_PACKAGE_MANAGER must not be empty"

    exit 3
fi

APT_FAST_MAX_CONNECTION="$(get_state "APT_FAST_MAX_CONNECTION")" || exit 2
if [[ -z "$APT_FAST_MAX_CONNECTION" ]]; then
    log_error "APT_FAST_MAX_CONNECTION must not be empty"

    exit 3
fi

APT_FAST_SUPPRESS_CONFIRM_DIALOG="$(get_state "APT_FAST_SUPPRESS_CONFIRM_DIALOG")" || exit 2
if [[ -z "$APT_FAST_SUPPRESS_CONFIRM_DIALOG" ]]; then
    log_error "APT_FAST_SUPPRESS_CONFIRM_DIALOG must not be empty"

    exit 3
fi

configs="apt-fast apt-fast/aptmanager string $APT_FAST_PACKAGE_MANAGER
apt-fast apt-fast/maxdownloads string $APT_FAST_MAX_CONNECTION
apt-fast apt-fast/dlflag boolean $APT_FAST_SUPPRESS_CONFIRM_DIALOG"

message="[$CANONICAL_ID] Injecting apt-fast values via debconf-set-selections, configs:
$configs"

log_info "$message"

printf '%s\n' "$configs" | sudo debconf-set-selections &&
    sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y apt-fast
