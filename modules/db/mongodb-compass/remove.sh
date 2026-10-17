#!/usr/bin/env bash
set -euo pipefail

source "$LIB_REMOVER/package.sh"
source "$LIB_REMOVER/home.sh"

package_remove "$CANONICAL_ID" "mongodb-compass" || exit $?

purge_home_paths "$CANONICAL_ID" "MongoDB Compass" "mongodb/compass"
