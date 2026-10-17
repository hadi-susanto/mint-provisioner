#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_MYSQL_DEBCONF_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_MYSQL_DEBCONF_LOADED=1

source "$LIB_COMMON/common.sh"
source "$LIB_INSTALLER/state.sh"

##
# preseed_mysql_root_password <canonical_id> <password>
#
# Preseeds the mysql-community-server root password questions so the package
# installation does not prompt, and records the root login method in the
# in-memory state key MYSQL_ROOT_LOGIN (socket or password). The password
# itself is never stored in the state. An empty password makes root
# authenticate through auth_socket (sudo mysql). The server postinst clears
# the preseeded answers after setting the password.
#
# Parameters:
#   canonical_id - Canonical module ID used for logging.
#   password - Root password; may be empty.
#
# Return:
#   1 - debconf-set-selections failed.
#
preseed_mysql_root_password() {
    local canonical_id="$1"
    local password="$2"
    local tag="debconf:$canonical_id"
    local configs

    configs="mysql-community-server mysql-community-server/root-pass password $password
mysql-community-server mysql-community-server/re-root-pass password $password"

    tlog_info "$tag" "Preseeding the MySQL root password via debconf-set-selections"

    if ! printf '%s\n' "$configs" | sudo debconf-set-selections; then
        tlog_error "$tag" "Failed to preseed the MySQL root password"

        return 1
    fi

    if [[ -z "$password" ]]; then
        set_state "MYSQL_ROOT_LOGIN" "socket"
    else
        set_state "MYSQL_ROOT_LOGIN" "password"
    fi
}
