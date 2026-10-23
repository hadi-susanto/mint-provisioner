#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/apt.sh"
source "$LIB_INSTALLER/messages.sh"

apt_install "$CANONICAL_ID" gram

add_message "$CANONICAL_ID" "info" \
    "To open XML files with Gram as default, see FAQ.md: XML Files Still Open in My Old Editor"
