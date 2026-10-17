#!/usr/bin/env bash
set -euo pipefail

source "$LIB_REMOVER/binary.sh"

remove_from_path "$CANONICAL_ID" || exit $?
remove_install_dir "$CANONICAL_ID"
