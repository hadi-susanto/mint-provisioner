#!/usr/bin/env bash
set -euo pipefail

#
# Installs Flameshot from a previously downloaded .deb package.
#
# Exit codes:
#   0 - Installation successful
#   1 - flameshot.path state file not found
#   2 - Invalid or missing .deb package
#   3 - Package installation failed
#

# shellcheck source=/dev/null
source "${LIB_DIR}/installer_apt.sh"
source "${LIB_DIR}/messages.sh"
source "${LIB_DIR}/state.sh"

load_states "$CANONICAL_ID" || exit 1
DEB_FILE="$(get_state "DEB_FILE")" || exit 1

log_info "[$CANONICAL_ID] Package path: ${DEB_FILE}"

case "$DEB_FILE" in
    *.deb)
        ;;
    *)
        log_error "[$CANONICAL_ID] Expected a .deb file, got: ${DEB_FILE}"

        exit 2
        ;;
esac

if [[ ! -f "$DEB_FILE" ]]; then
    log_error "[$CANONICAL_ID] Package file not found: ${DEB_FILE}"

    exit 2
fi

log_info "[$CANONICAL_ID] Installing package"

#
# Breaking change warning for Flameshot >= 14
#
if [[ -f "$DEB_FILE" ]]; then
    # Extract version from .deb file using dpkg-deb
    version="$(dpkg-deb -f "$DEB_FILE" Version | grep -oP '^\d+' || true)"
    
    if [[ -n "$version" ]] && [[ "$version" -ge 14 ]]; then
        msg="Flameshot >= 14 is introduce new breaking changes in their engine (X11 maybe affected)"
        msg+=$'\n'"If you're unable to to perform screenshot please enable Legacy X11 Screenshot Fallback"
        msg+=$'\n'"Refer to https://github.com/flameshot-org/flameshot/releases/tag/v14.0.0"
        
        log_info "[$CANONICAL_ID] $msg"
        add_message "$CANONICAL_ID" "info" "$msg"
    fi
fi

if ! apt_install "$DEB_FILE"; then
    log_error "[$CANONICAL_ID] Package installation failed"

    exit 3
fi

log_info "[$CANONICAL_ID] Package installed successfully"

exit 0
