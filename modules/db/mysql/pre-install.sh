#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/state.sh"
source "$LIB_WORKFLOW/$CANONICAL_ID/repository.sh"

load_states "$CANONICAL_ID" || exit $?
series="$(get_state "MYSQL_SERIES")" || exit $?

add_mysql_repository_component "$CANONICAL_ID" "$series" 1
