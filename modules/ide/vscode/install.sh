#!/usr/bin/env bash
set -euo pipefail

source "${LIB_INSTALLER}/apt.sh"
source "${LIB_INSTALLER}/messages.sh"
source "${LIB_INSTALLER}/state.sh"

load_states "$CANONICAL_ID" || exit $?
package="$(get_state "VSCODE_PACKAGE")" || exit $?

if [[ -z "$package" ]]; then
    tlog_error "$CANONICAL_ID" "VSCODE_PACKAGE must not be empty"

    exit 1
fi

configs="$package $package/add-microsoft-repo boolean false"
message="Disable automatic microsoft APT configuration via debconf-set-selections, configs:
$configs"

log_info "$message"

if ! printf '%s\n' "$configs" | sudo debconf-set-selections; then
    tlog_error "$CANONICAL_ID" "Failed to configure Microsoft repository selection"

    exit 1
fi

apt_install "$CANONICAL_ID" "$package" || exit $?
add_message "$CANONICAL_ID" "info" "Installed package: $package"
