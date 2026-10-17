#!/usr/bin/env bash
set -euo pipefail

source "$LIB_REMOVER/package.sh"
source "$LIB_REMOVER/home.sh"

package_remove "$CANONICAL_ID" "cudatext" "cudatext-gtk2" "cudatext-gtk3" "cudatext-qt5" "cudatext-qt6" || exit $?

purge_home_paths "$CANONICAL_ID" "cudatext"
