#!/usr/bin/env bash

source "${LIB_DIR}/common.sh"

__is_pgadmin_package_installed() {
    local package="$1"

    dpkg-query \
        --show \
        --showformat='${db:Status-Abbrev}' \
        "$package" 2>/dev/null |
        grep -q '^ii '
}

case "${PGADMIN_UI:-desktop}" in
    desktop)
        __is_pgadmin_package_installed "pgadmin4-desktop"
        ;;

    web)
        __is_pgadmin_package_installed "pgadmin4-web"
        ;;

    both)
        __is_pgadmin_package_installed "pgadmin4" || {
            __is_pgadmin_package_installed "pgadmin4-desktop" &&
                __is_pgadmin_package_installed "pgadmin4-web"
        }
        ;;

    *)
        log_error \
            "[$CANONICAL_ID] Invalid PGADMIN_UI value: $PGADMIN_UI. Expected desktop, web, or both."

        exit 2
        ;;
esac
