#!/usr/bin/env bash
set -euo pipefail

source "${LIB_DIR}/common.sh"

__is_pgadmin_package_installed() {
    local package="${1:-}"
    local rc
    local status

    if [[ -z "$package" ]]; then
        log_error "[$CANONICAL_ID] Missing pgAdmin package name"

        return 2
    fi

    if status="$(
        dpkg-query \
            --show \
            --showformat='${db:Status-Abbrev}' \
            "$package" 2>/dev/null
    )"; then
        if [[ "$status" == "ii "* ]]; then
            return 0
        fi

        return 1
    else
        rc=$?
    fi

    if ((rc == 1)); then
        return 1
    fi

    log_error "[$CANONICAL_ID] Failed to query package status for $package"

    return 2
}

case "${PGADMIN_UI:-desktop}" in
    desktop)
        __is_pgadmin_package_installed "pgadmin4-desktop"
        ;;

    web)
        __is_pgadmin_package_installed "pgadmin4-web"
        ;;

    both)
        if __is_pgadmin_package_installed "pgadmin4"; then
            exit 0
        else
            rc=$?
        fi

        ((rc == 1)) || exit "$rc"

        if __is_pgadmin_package_installed "pgadmin4-desktop"; then
            __is_pgadmin_package_installed "pgadmin4-web"
        else
            rc=$?
            ((rc == 1)) && exit 1

            exit "$rc"
        fi
        ;;

    *)
        log_error \
            "[$CANONICAL_ID] Invalid PGADMIN_UI value: $PGADMIN_UI. Expected desktop, web, or both."

        exit 2
        ;;
esac
