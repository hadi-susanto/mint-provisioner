#!/usr/bin/env bash
set -euo pipefail

source "$LIB_REMOVER/package.sh"
source "$LIB_REMOVER/apt.sh"
source "$LIB_REMOVER/data.sh"
source "$LIB_REMOVER/home.sh"

package_remove "$CANONICAL_ID" "pgadmin4-desktop" "pgadmin4-web" "pgadmin4" || exit $?
remove_apt_repository "$CANONICAL_ID" || exit $?
remove_data_dir "$CANONICAL_ID" "/var/lib/pgadmin" || exit $?
purge_home_paths "$CANONICAL_ID" "pgadmin" "pgadmin4"
