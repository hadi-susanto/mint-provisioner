#!/usr/bin/env bash
set -euo pipefail

source "$LIB_REMOVER/package.sh"
source "$LIB_REMOVER/data.sh"
source "$LIB_WORKFLOW/$CANONICAL_ID/debconf.sh"
source "$LIB_WORKFLOW/$CANONICAL_ID/repository.sh"

# Keep the package's own data-directory cleanup consistent with mp purge.
if [[ "${PURGE:-false}" == "true" ]]; then
    preseed_mysql_remove_data_dir "$CANONICAL_ID" || exit $?
fi

package_remove "$CANONICAL_ID" "mysql-community-server" "mysql-community-client" || exit $?
remove_mysql_repository_component \
    "$CANONICAL_ID" \
    "mysql-8.4-lts" \
    "mysql-9.7-lts" \
    "mysql-innovation" || exit $?
remove_data_dir "$CANONICAL_ID" "/var/lib/mysql"
