#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/$CANONICAL_ID/debconf.sh"
source "$LIB_WORKFLOW/$CANONICAL_ID/resolver.sh"

resolve_mysql_series "${MYSQL_SERIES:-mysql-9.7-lts}" || exit $?
preseed_mysql_root_password "$CANONICAL_ID" "" || exit $?
save_states "$CANONICAL_ID"
