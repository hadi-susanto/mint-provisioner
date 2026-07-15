#!/usr/bin/env bash

source "${LIB_DIR}/common.sh"
source "${LIB_DIR}/state.sh"

load_states "$CANONICAL_ID" || log_warn "[$CANONICAL_ID] Failed to load states. Falling back to default values."

log_info "[$CANONICAL_ID] Preparing non-interactive apt-fast installation via debconf-set-selections"

APT_FAST_PACKAGE_MANAGER="$(get_state "APT_FAST_PACKAGE_MANAGER" "apt-get")"
APT_FAST_MAX_CONNECTION="$(get_state "APT_FAST_MAX_CONNECTION" "5")"
APT_FAST_SUPPRESS_CONFIRM_DIALOG="$(get_state "APT_FAST_SUPPRESS_CONFIRM_DIALOG" "false")"

configs="apt-fast apt-fast/aptmanager string $APT_FAST_PACKAGE_MANAGER
apt-fast apt-fast/maxdownloads string $APT_FAST_MAX_CONNECTION
apt-fast apt-fast/dlflag boolean $APT_FAST_SUPPRESS_CONFIRM_DIALOG"

message="[$CANONICAL_ID] Injecting apt-fast values via debconf-set-selections, configs:
$configs"

log_info "$message"

printf '%s\n' "$configs" | sudo debconf-set-selections &&
    sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y apt-fast
