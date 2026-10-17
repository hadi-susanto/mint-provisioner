#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/$CANONICAL_ID/debconf.sh"
source "$LIB_WORKFLOW/$CANONICAL_ID/resolver.sh"

ensure_no_distro_mysql_server "$CANONICAL_ID" || exit $?
resolve_mysql_series "${MYSQL_SERIES:-mysql-9.7-lts}" || exit $?

if mysql_data_dir_exists; then
    set_state "MYSQL_ROOT_LOGIN" "existing"
else
    set_state "MYSQL_ROOT_LOGIN" "socket"
fi

save_states "$CANONICAL_ID"
