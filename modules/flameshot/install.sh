#!/usr/bin/env bash

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

MODULE="flameshot"
STATE_FILE="${STATE_DIR}/flameshot.path"

log_info "[$MODULE] Looking for state file: ${STATE_FILE}"

if [[ ! -f "$STATE_FILE" ]]; then
    log_error "[$MODULE] State file not found"
    exit 1
fi

log_info "[$MODULE] Reading package path from state file"

read -r DEB_FILE < "$STATE_FILE"

log_info "[$MODULE] Package path: ${DEB_FILE}"

case "$DEB_FILE" in
    *.deb)
        ;;
    *)
        log_error "[$MODULE] Expected a .deb file, got: ${DEB_FILE}"

        exit 2
        ;;
esac

if [[ ! -f "$DEB_FILE" ]]; then
    log_error "[$MODULE] Package file not found: ${DEB_FILE}"

    exit 2
fi

log_info "[$MODULE] Installing package"

#
# Breaking change warning for Flameshot >= 14
#
if [[ -f "$DEB_FILE" ]]; then
    # Extract version from .deb file using dpkg-deb
    version=$(dpkg-deb -f "$DEB_FILE" Version | grep -oP '^\d+' || true)
    
    if [[ -n "$version" ]] && [[ "$version" -ge 14 ]]; then
        msg="Flameshot >= 14 is introduce new breaking changes in their engine (X11 maybe affected)"
        msg+=$'\n'"If you're unable to to perform screenshot please enable Legacy X11 Screenshot Fallback"
        msg+=$'\n'"Refer to https://github.com/flameshot-org/flameshot/releases/tag/v14.0.0"
        
        log_info "[$MODULE] $msg"
        post_message "$MODULE" "$msg"
    fi
fi

if ! apt_install "$DEB_FILE"; then
    log_error "[$MODULE] Package installation failed"

    exit 3
fi

log_info "[$MODULE] Package installed successfully"

exit 0
