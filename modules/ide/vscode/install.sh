#!/usr/bin/env bash
set -euo pipefail

source "${LIB_INSTALLER}/apt.sh"
source "${LIB_INSTALLER}/messages.sh"
source "${LIB_INSTALLER}/state.sh"

if ! load_states "$CANONICAL_ID"; then
    tlog_error "$CANONICAL_ID" "Visual Studio Code installation state was not found"

    exit 1
fi

package="$(get_state "VSCODE_PACKAGE")" || exit 2

if [[ -z "$package" ]]; then
    tlog_error "$CANONICAL_ID" "VSCODE_PACKAGE must not be empty"

    exit 3
fi

configs="$package $package/add-microsoft-repo boolean false"

message="Disable automatic microsoft APT configuration via debconf-set-selections, configs:
$configs"

log_info "$message"

if ! printf '%s\n' "$configs" | sudo debconf-set-selections; then
    tlog_error "$CANONICAL_ID" "Failed to configure Microsoft repository selection"

    exit 4
fi

if ! apt_install "$CANONICAL_ID" "$package"; then
    add_message "$CANONICAL_ID" "warn" "Installation failed: $package"

    exit 5
fi

add_message "$CANONICAL_ID" "info" "Installed package: $package"
