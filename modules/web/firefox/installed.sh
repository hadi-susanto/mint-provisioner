#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/detection.sh"

# Mint and Ubuntu ship a distribution Firefox, so the package alone does not
# prove this module's Mozilla repository and pin are in place.
if [[ ! -f "/etc/apt/preferences.d/mozilla.pref" ]]; then
    exit 1
fi

package_installed "$CANONICAL_ID" "firefox"
