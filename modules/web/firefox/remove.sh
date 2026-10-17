#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/messages.sh"
source "$LIB_REMOVER/package.sh"
source "$LIB_REMOVER/apt.sh"
source "$LIB_REMOVER/system.sh"

package_remove "$CANONICAL_ID" "firefox" || exit $?
remove_apt_repository "$CANONICAL_ID" "mozilla" || exit $?

remove_system_file "$CANONICAL_ID" "/etc/apt/preferences.d/mozilla.pref" || exit $?

add_message "$CANONICAL_ID" "info" \
    "Firefox profiles in ~/.mozilla are never deleted."
