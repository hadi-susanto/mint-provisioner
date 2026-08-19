#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/messages.sh"
source "$LIB_WORKFLOW/stateful-deb-install.sh"

stateful_deb_install "$CANONICAL_ID" "DEB_FILE" || exit $?

msg="Flameshot >= 14 is introduce new breaking changes in their engine (X11 maybe affected)
If you're unable to to perform screenshot please enable Legacy X11 Screenshot Fallback
Refer to https://github.com/flameshot-org/flameshot/releases/tag/v14.0.0"

tlog_info "install:$CANONICAL_ID" "$msg"
add_message "$CANONICAL_ID" "info" "$msg"
