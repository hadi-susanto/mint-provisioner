#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_MYSQL_TOOLS_RESOLVER_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_MYSQL_TOOLS_RESOLVER_LOADED=1

source "$LIB_COMMON/common.sh"
source "$LIB_INSTALLER/state.sh"

##
# resolve_mysql_tools_connector <connector>
#
# Resolves the MySQL connector package to install and stores it in the
# MYSQL_TOOLS_PACKAGE state.
#
# Parameters:
#   connector - Connector name: java, python, odbc, or cpp (case-insensitive).
#
# Return:
#   0 - Package selection resolved successfully.
#   1 - Connector value is empty or invalid.
#
resolve_mysql_tools_connector() {
    local connector="$1"
    local tag="connector-resolver:$CANONICAL_ID"
    local package

    if [[ -z "$connector" ]]; then
        tlog_error "$tag" \
            "MYSQL_TOOLS_CONNECTOR is required; supported values: java, python, odbc, cpp"

        return 1
    fi

    case "${connector,,}" in
        java)
            package="mysql-connector-j"
            ;;
        python)
            package="mysql-connector-python-py3"
            ;;
        odbc)
            package="mysql-connector-odbc"
            ;;
        cpp)
            package="libmysqlcppconn-dev"
            ;;
        *)
            tlog_error "$tag" \
                "Invalid MYSQL_TOOLS_CONNECTOR value: %s; supported values: java, python, odbc, cpp" \
                "$connector"

            return 1
            ;;
    esac

    set_state "MYSQL_TOOLS_PACKAGE" "$package" || return $?
    tlog_info "$tag" "Mark MySQL connector for installation (%s)" "$package"
}
