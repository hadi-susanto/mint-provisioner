#!/usr/bin/env bash
set -euo pipefail

source "$LIB_REMOVER/desktop.sh"
source "$LIB_REMOVER/binary.sh"
source "$LIB_REMOVER/home.sh"
source "$LIB_REMOVER/system.sh"

remove_system_file "$CANONICAL_ID" "/usr/local/bin/tlp-ui" || exit $?
remove_desktop_entry "$CANONICAL_ID" "tlp-ui" || exit $?
remove_install_dir "$CANONICAL_ID" || exit $?
purge_home_paths "$CANONICAL_ID" "tlpui"
