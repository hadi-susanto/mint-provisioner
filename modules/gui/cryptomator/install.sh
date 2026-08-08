#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/apt.sh"

apt_install "$CANONICAL_ID" cryptomator
