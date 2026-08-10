#!/usr/bin/env bash
set -euo pipefail

source "${LIB_INSTALLER}/apt.sh"
source "${LIB_INSTALLER}/messages.sh"

apt_install "$CANONICAL_ID" dconf-editor

message="Dconf Editor provides direct access to low-level desktop settings.
Modify values carefully because invalid settings may cause unexpected desktop behavior.

Linux Mint battery settings can be found under:

    /org/cinnamon/settings-daemon/plugins/power/"

add_message "$CANONICAL_ID" "warn" "$message"
