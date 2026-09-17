#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_PGADMIN_RESOLVER_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_PGADMIN_RESOLVER_LOADED=1

source "$LIB_COMMON/common.sh"
source "$LIB_INSTALLER/state.sh"

##
# resolve_pgadmin_package <ui>
#
# Resolves the pgAdmin 4 package based on the selected UI type.
#
# Parameters:
#   ui - UI type to install (desktop, web, or both).
#
# Return:
#   0 - Package selection resolved successfully.
#   1 - UI value is invalid.
#
resolve_pgadmin_package() {
    local ui="$1"
    local tag="package-resolver:$CANONICAL_ID"
    local package

    case "${ui,,}" in
        desktop)
            set_state "PGADMIN_PACKAGE" "pgadmin4-desktop"
            tlog_info "$tag" "Mark pgAdmin 4 Desktop for installation (pgadmin4-desktop)"
            ;;
        web)
            set_state "PGADMIN_PACKAGE" "pgadmin4-web"
            tlog_info "$tag" "Mark pgAdmin 4 Web for installation (pgadmin4-web)"
            ;;
        both)
            set_state "PGADMIN_PACKAGE" "pgadmin4"
            tlog_info "$tag" "Mark pgAdmin 4 Desktop and Web for installation (pgadmin4)"
            ;;
        *)
            tlog_error "$tag" \
                "Invalid pgAdmin UI value: %s. Expected desktop, web, or both." "$ui"

            return 1
            ;;
    esac
}
