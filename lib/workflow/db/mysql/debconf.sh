#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_MYSQL_DEBCONF_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_MYSQL_DEBCONF_LOADED=1

source "$LIB_COMMON/common.sh"

readonly __MYSQL_DATA_DIR="/var/lib/mysql"

__mysql_debconf_set() {
    local canonical_id="$1"
    local configs="$2"
    local tag="debconf:$canonical_id"

    if ! printf '%s\n' "$configs" | sudo debconf-set-selections; then
        tlog_error "$tag" "Failed to preseed mysql-community-server answers"

        return 1
    fi
}

##
# mysql_data_dir_exists
#
# Checks whether a MySQL data directory is present. The server package applies
# a preseeded root password only to a fresh data directory, so an existing one
# keeps its root credentials.
#
# Return:
#   0 - /var/lib/mysql exists (directory or symlink).
#   1 - No data directory exists.
#
mysql_data_dir_exists() {
    [[ -d "$__MYSQL_DATA_DIR" || -L "$__MYSQL_DATA_DIR" ]]
}

##
# validate_mysql_root_password <password>
#
# Accepts printable ASCII without backslashes. debconf-set-selections joins a
# line ending in a backslash with the next one, and the server postinst cannot
# quote non-ASCII or control characters safely.
#
# Parameters:
#   password - Root password to check; may be empty.
#
# Return:
#   1 - The password contains unsupported characters.
#
validate_mysql_root_password() {
    local password="$1"
    local LC_ALL=C
    local printable='^[[:print:]]*$'

    if [[ "$password" =~ $printable && "$password" != *\\* ]]; then
        return 0
    fi

    tlog_error "mysql-password" \
        "Use printable ASCII characters only, without backslashes"

    return 1
}

##
# preseed_mysql_root_password <canonical_id> <password>
#
# Preseeds the mysql-community-server root password questions so the package
# installation does not prompt. An empty password makes root authenticate
# through auth_socket (sudo mysql). The server postinst clears the answers
# after applying them to a fresh data directory.
#
# Parameters:
#   canonical_id - Canonical module ID used for logging.
#   password - Root password validated by validate_mysql_root_password.
#
# Return:
#   1 - debconf-set-selections failed.
#
preseed_mysql_root_password() {
    local canonical_id="$1"
    local password="$2"

    tlog_info "debconf:$canonical_id" "Preseeding the MySQL root password"
    __mysql_debconf_set "$canonical_id" \
        "mysql-community-server mysql-community-server/root-pass password $password
mysql-community-server mysql-community-server/re-root-pass password $password"
}

##
# preseed_mysql_existing_data_dir <canonical_id>
#
# Marks the "existing data directory" note and the root password questions as
# answered, so installing over a kept /var/lib/mysql does not prompt.
#
# Parameters:
#   canonical_id - Canonical module ID used for logging.
#
# Return:
#   1 - debconf-set-selections failed.
#
preseed_mysql_existing_data_dir() {
    local canonical_id="$1"

    tlog_info "debconf:$canonical_id" "Keeping the root credentials of the existing data directory"
    __mysql_debconf_set "$canonical_id" \
        "mysql-community-server mysql-community-server/data-dir note
mysql-community-server mysql-community-server/root-pass password
mysql-community-server mysql-community-server/re-root-pass password"
}

##
# preseed_mysql_remove_data_dir <canonical_id>
#
# Answers the package's "remove data directories" question with yes, so
# `apt-get purge` removes the data, log, and keyring directories without
# prompting.
#
# Parameters:
#   canonical_id - Canonical module ID used for logging.
#
# Return:
#   1 - debconf-set-selections failed.
#
preseed_mysql_remove_data_dir() {
    local canonical_id="$1"

    tlog_info "debconf:$canonical_id" "Preseeding removal of the MySQL data directories"
    __mysql_debconf_set "$canonical_id" \
        "mysql-community-server mysql-community-server/remove-data-dir boolean true"
}
