#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/state.sh"
source "$LIB_WORKFLOW/$CANONICAL_ID/debconf.sh"
source "$LIB_WORKFLOW/$CANONICAL_ID/repository.sh"

load_states "$CANONICAL_ID" || exit $?
series="$(get_state "MYSQL_SERIES")" || exit $?
root_login="$(get_state "MYSQL_ROOT_LOGIN")" || exit $?

case "$root_login" in
    socket)
        preseed_mysql_root_password "$CANONICAL_ID" "" || exit $?
        ;;
    existing)
        preseed_mysql_existing_data_dir "$CANONICAL_ID" || exit $?
        ;;
esac

add_mysql_repository_component "$CANONICAL_ID" "$series" 1
