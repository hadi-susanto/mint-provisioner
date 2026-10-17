#!/usr/bin/env bash
set -euo pipefail

source "$LIB_REMOVER/package.sh"
source "$LIB_WORKFLOW/db/mysql/repository.sh"

package_remove \
    "$CANONICAL_ID" \
    "mysql-connector-j" \
    "mysql-connector-python-py3" \
    "mysql-connector-odbc" \
    "libmysqlcppconn-dev" || exit $?
remove_mysql_repository_component "$CANONICAL_ID" "mysql-tools"
