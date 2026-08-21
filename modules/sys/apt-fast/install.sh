#!/usr/bin/env bash
set -euo pipefail

source "${LIB_COMMON}/common.sh"
source "${LIB_INSTALLER}/messages.sh"
source "${LIB_INSTALLER}/state.sh"

load_states "$CANONICAL_ID" || exit $?

tlog_info "install:$CANONICAL_ID" "Preparing non-interactive apt-fast installation via debconf-set-selections"
package_manager="$(get_state "APT_FAST_PACKAGE_MANAGER")" || exit 2
if [[ -z "$package_manager" ]]; then
    tlog_error "install:$CANONICAL_ID" "APT_FAST_PACKAGE_MANAGER must not be empty"

    exit 3
fi

max_connection="$(get_state "APT_FAST_MAX_CONNECTION")" || exit 2
if [[ -z "$max_connection" ]]; then
    tlog_error "install:$CANONICAL_ID" "APT_FAST_MAX_CONNECTION must not be empty"

    exit 3
fi

suppress_confirm_dialog="$(get_state "APT_FAST_SUPPRESS_CONFIRM_DIALOG")" || exit 2
if [[ -z "$suppress_confirm_dialog" ]]; then
    tlog_error "install:$CANONICAL_ID" "APT_FAST_SUPPRESS_CONFIRM_DIALOG must not be empty"

    exit 3
fi

configs="apt-fast apt-fast/aptmanager string $package_manager
apt-fast apt-fast/maxdownloads string $max_connection
apt-fast apt-fast/dlflag boolean $suppress_confirm_dialog"

message="Injecting apt-fast values via debconf-set-selections, configs:
$configs"

tlog_info "install:$CANONICAL_ID" "$message"

printf '%s\n' "$configs" | sudo debconf-set-selections &&
    sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y apt-fast

add_system_toolkit_message "$CANONICAL_ID"

message="Unless System Toolkit is used to enable apt-fast
autocompletion, install the shell completions
manually:
  https://github.com/ilikenwf/apt-fast#autocompletion"

add_message "$CANONICAL_ID" "info" "$message"
