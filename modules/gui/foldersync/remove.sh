#!/usr/bin/env bash
set -euo pipefail

source "$LIB_REMOVER/package.sh"
source "$LIB_REMOVER/home.sh"

# dpkg purge also deletes the APT source and signing key that the package ships.
package_remove "$CANONICAL_ID" "tacit-dynamics-aps-foldersync-desktop" || exit $?

purge_home_paths "$CANONICAL_ID" "foldersync" "java/.userPrefs/dk/tacit/desktop/foldersync"
