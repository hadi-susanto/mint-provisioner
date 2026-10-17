#!/usr/bin/env bash
set -euo pipefail

source "$LIB_REMOVER/binary.sh"
source "$LIB_REMOVER/desktop.sh"
source "$LIB_REMOVER/jetbrains.sh"

remove_desktop_entry "$CANONICAL_ID" "rustrover" || exit $?
remove_symlink "$CANONICAL_ID" "rustrover" || exit $?
remove_install_dir "$CANONICAL_ID" || exit $?
purge_jetbrains_dirs "$CANONICAL_ID" "RustRover"
