#!/usr/bin/env bash
set -euo pipefail

source "$LIB_REMOVER/binary.sh"
source "$LIB_REMOVER/desktop.sh"
source "$LIB_REMOVER/home.sh"

remove_desktop_entry "$CANONICAL_ID" "kitty" || exit $?
remove_desktop_entry "$CANONICAL_ID" "kitty-open" || exit $?
remove_symlink "$CANONICAL_ID" "kitty" || exit $?
remove_symlink "$CANONICAL_ID" "kitten" || exit $?
remove_install_dir "$CANONICAL_ID" || exit $?
purge_home_paths "$CANONICAL_ID" "kitty"
