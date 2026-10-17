#!/usr/bin/env bash
set -euo pipefail

source "$LIB_REMOVER/package.sh"
source "$LIB_REMOVER/home.sh"

package_remove "$CANONICAL_ID" "fman" || exit $?

purge_home_paths "$CANONICAL_ID" "fman"
