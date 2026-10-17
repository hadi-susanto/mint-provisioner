#!/usr/bin/env bash
set -euo pipefail

source "$LIB_REMOVER/binary.sh"

remove_install_dir "$CANONICAL_ID"
