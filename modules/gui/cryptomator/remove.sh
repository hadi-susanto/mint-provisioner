#!/usr/bin/env bash
set -euo pipefail

source "$LIB_REMOVER/package.sh"
source "$LIB_REMOVER/apt.sh"
source "$LIB_REMOVER/home.sh"

package_remove "$CANONICAL_ID" "cryptomator" || exit $?
remove_apt_repository "$CANONICAL_ID" || exit $?
remove_ppa "$CANONICAL_ID" "ppa:sebastian-stenzel/cryptomator" || exit $?
purge_home_paths "$CANONICAL_ID" "Cryptomator"
