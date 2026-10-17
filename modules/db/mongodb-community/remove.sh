#!/usr/bin/env bash
set -euo pipefail

source "$LIB_REMOVER/package.sh"
source "$LIB_REMOVER/apt.sh"
source "$LIB_REMOVER/data.sh"

package_remove "$CANONICAL_ID" "mongodb-org" || exit $?
remove_apt_repository "$CANONICAL_ID" || exit $?
remove_data_dir "$CANONICAL_ID" "/var/lib/mongodb"
