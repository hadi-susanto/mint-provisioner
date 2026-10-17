#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_MYSQL_RESOLVER_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_MYSQL_RESOLVER_LOADED=1

source "$LIB_COMMON/common.sh"
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
