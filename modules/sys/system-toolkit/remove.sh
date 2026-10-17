#!/usr/bin/env bash
set -euo pipefail

source "$LIB_REMOVER/binary.sh"

for link_name in "syskit-bash" "syskit-zsh" "syskit-bin" "syskit-cfg"; do
    remove_symlink "$CANONICAL_ID" "$link_name" || exit $?
done

remove_install_dir "$CANONICAL_ID"
