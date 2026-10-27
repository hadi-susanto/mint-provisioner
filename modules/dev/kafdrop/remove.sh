#!/usr/bin/env bash
set -euo pipefail

source "$LIB_REMOVER/binary.sh"
source "$LIB_REMOVER/desktop.sh"

remove_desktop_entry "$CANONICAL_ID" "kafdrop" || exit $?
remove_symlink "$CANONICAL_ID" "kafdrop" || exit $?
remove_install_dir "$CANONICAL_ID"
