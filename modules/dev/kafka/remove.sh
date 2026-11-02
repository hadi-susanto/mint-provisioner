#!/usr/bin/env bash
set -euo pipefail

source "$LIB_REMOVER/binary.sh"
source "$LIB_REMOVER/desktop.sh"

remove_desktop_entry "$CANONICAL_ID" "kafka" || exit $?
remove_symlink "$CANONICAL_ID" "kafka-server" || exit $?
remove_symlink "$CANONICAL_ID" "kafka-initialize" || exit $?
remove_from_path "$CANONICAL_ID" || exit $?
remove_install_dir "$CANONICAL_ID"
