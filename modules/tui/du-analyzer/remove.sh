#!/usr/bin/env bash
set -euo pipefail

source "$LIB_REMOVER/binary.sh"

remove_symlink "$CANONICAL_ID" "dua" || exit $?
remove_install_dir "$CANONICAL_ID"
