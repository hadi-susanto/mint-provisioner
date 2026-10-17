#!/usr/bin/env bash
set -euo pipefail

source "$LIB_REMOVER/package.sh"
source "$LIB_INSTALLER/messages.sh"

package_remove "$CANONICAL_ID" "dnscrypt-proxy" || exit $?

message="DNSCrypt Proxy has been removed.

If you pointed your network connection at its loopback DNS address,
switch the connection back to automatic DNS to restore name resolution."

add_message "$CANONICAL_ID" "info" "$message"
