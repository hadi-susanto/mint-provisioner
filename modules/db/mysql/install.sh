#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/apt.sh"
source "$LIB_INSTALLER/messages.sh"
source "$LIB_INSTALLER/state.sh"

load_states "$CANONICAL_ID" || exit $?
root_login="$(get_state "MYSQL_ROOT_LOGIN")" || exit $?
apt_install "$CANONICAL_ID" mysql-community-server || exit $?

if [[ "$root_login" == "socket" ]]; then
    add_message "$CANONICAL_ID" "info" "MySQL root has no password; log in with: sudo mysql"
fi
