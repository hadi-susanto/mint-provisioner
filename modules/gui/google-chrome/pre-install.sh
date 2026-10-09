#!/usr/bin/env bash
set -euo pipefail

source "${LIB_INSTALLER}/apt.sh"

# URI, suite, component, and signing key match Google's official package
# (google-chrome-stable postinst, which writes google-chrome.sources). Use the
# same filename so the package updates this source instead of adding a duplicate.
install_asc_key \
    "$CANONICAL_ID" \
    "https://dl.google.com/linux/linux_signing_key.pub" \
    "https://dl.google.com/linux/chrome-stable/deb/" \
    "stable" \
    "main" \
    "google-chrome"
