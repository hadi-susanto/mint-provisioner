#!/usr/bin/env bash
set -euo pipefail

source "$LIB_REMOVER/package.sh"
source "$LIB_REMOVER/data.sh"
source "$LIB_WORKFLOW/$CANONICAL_ID/repository.sh"

package_remove "$CANONICAL_ID" "mysql-community-server" "mysql-community-client" || exit $?
remove_mysql_repository_component \
    "$CANONICAL_ID" \
    "mysql-8.4-lts" \
    "mysql-9.7-lts" \
    "mysql-innovation" || exit $?
remove_data_dir "$CANONICAL_ID" "/var/lib/mysql"
