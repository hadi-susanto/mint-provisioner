#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/detection.sh"

package_installed \
    "$CANONICAL_ID" \
    "google-chrome-stable" \
    "google-chrome-beta" \
    "google-chrome-unstable" \
    "google-chrome-canary"
