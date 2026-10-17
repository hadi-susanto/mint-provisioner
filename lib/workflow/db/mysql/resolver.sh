#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_MYSQL_RESOLVER_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_MYSQL_RESOLVER_LOADED=1

source "$LIB_COMMON/common.sh"
source "$LIB_INSTALLER/detection.sh"
source "$LIB_INSTALLER/state.sh"

##
# resolve_mysql_series <series>
#
# Stores the selected MySQL Server series (APT repository component) in the
# module state key MYSQL_SERIES.
#
# Parameters:
#   series - mysql-8.4-lts, mysql-9.7-lts, or mysql-innovation.
#
# Return:
#   0 - Series selection resolved successfully.
#   1 - Series value is invalid.
#
resolve_mysql_series() {
    local series="$1"
    local tag="series-resolver:$CANONICAL_ID"

    case "$series" in
        mysql-8.4-lts | mysql-9.7-lts | mysql-innovation)
            set_state "MYSQL_SERIES" "$series"
            tlog_info "$tag" "Mark MySQL Server series for installation: %s" "$series"
            ;;
        *)
            tlog_error "$tag" \
                "Invalid MySQL series: %s. Expected mysql-8.4-lts, mysql-9.7-lts, or mysql-innovation." \
                "$series"

            return 1
            ;;
    esac
}

##
# ensure_no_distro_mysql_server <canonical_id>
#
# Refuses to continue when an Ubuntu-packaged MySQL or MariaDB server is
# installed. Installing mysql-community-server would replace it and attempt an
# unsupported in-place upgrade of its data directory.
#
# Parameters:
#   canonical_id - Canonical module ID used for logging.
#
# Return:
#   1 - A distribution MySQL or MariaDB server is installed.
#   2 - The package query failed.
#
ensure_no_distro_mysql_server() {
    local canonical_id="$1"
    local status=0

    package_installed \
        "$canonical_id" \
        "mysql-server-core-8.0" \
        "mysql-server-core-8.4" \
        "mariadb-server-core" || status=$?

    if (( status == 1 )); then
        return 0
    fi

    if (( status == 0 )); then
        tlog_error "$canonical_id" \
            "An Ubuntu MySQL or MariaDB server is installed; remove it before installing MySQL Community Server"

        return 1
    fi

    return "$status"
}
