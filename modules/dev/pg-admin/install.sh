#!/usr/bin/env bash
set -euo pipefail

source "$LIB_COMMON/common.sh"
source "$LIB_INSTALLER/apt.sh"
source "$LIB_INSTALLER/messages.sh"
source "$LIB_INSTALLER/state.sh"

load_states "$CANONICAL_ID" ||
    tlog_warn "install:$CANONICAL_ID" \
        "Failed to load states; falling back to the default package"

PGADMIN_PACKAGE="pgadmin4-desktop"

if stored_package="$(get_state "PGADMIN_PACKAGE" 2>/dev/null)"; then
    PGADMIN_PACKAGE="$stored_package"
fi

tlog_info "install:$CANONICAL_ID" \
    "Installing package: %s" "$PGADMIN_PACKAGE"

if ! apt_install "$CANONICAL_ID" "$PGADMIN_PACKAGE"; then
    tlog_error "install:$CANONICAL_ID" "Package installation failed"
    add_message "$CANONICAL_ID" "warn" "Installation failed: $PGADMIN_PACKAGE"

    exit 1
fi

tlog_info "install:$CANONICAL_ID" "Package installed successfully"
add_message "$CANONICAL_ID" "info" "Installation success: $PGADMIN_PACKAGE"
