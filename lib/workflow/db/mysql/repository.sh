#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_MYSQL_REPOSITORY_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_MYSQL_REPOSITORY_LOADED=1

source "$LIB_COMMON/common.sh"
source "$LIB_INSTALLER/apt.sh"
source "$LIB_INSTALLER/distro.sh"
source "$LIB_REMOVER/apt.sh"

# The MySQL APT repository is shared by db/mysql and db/mysql-tools. Both must use
# one source file and keyring, otherwise apt rejects the conflicting Signed-By values.
readonly __MYSQL_KEY_URL="https://repo.mysql.com/RPM-GPG-KEY-mysql-2025"
readonly __MYSQL_REPO_URI="https://repo.mysql.com/apt/ubuntu"
readonly __MYSQL_REPO_NAME="mysql"
readonly __MYSQL_SOURCE_FILE="/etc/apt/sources.list.d/$__MYSQL_REPO_NAME.sources"

__mysql_repository_components() {
    if [[ ! -f "$__MYSQL_SOURCE_FILE" ]]; then
        return 0
    fi

    sed -n 's/^Components:[[:space:]]*//p' "$__MYSQL_SOURCE_FILE"
}

# Rewrites only the Components line of the existing source file, so changing
# components never deletes the shared source file or keyring.
__mysql_set_repository_components() {
    local canonical_id="$1"
    local components="$2"
    local tag="mysql-repo:$canonical_id"

    tlog_info "$tag" "Setting MySQL APT repository components: %s" "$components"

    if ! sudo sed -i "s/^Components:.*/Components: $components/" "$__MYSQL_SOURCE_FILE"; then
        tlog_error "$tag" "Failed to update %s" "$__MYSQL_SOURCE_FILE"

        return 1
    fi

    if ! sudo apt-get update; then
        tlog_error "$tag" "Failed to update package lists"

        return 1
    fi
}

##
# add_mysql_repository_component <canonical_id> <component> [replace]
#
# Adds a component to the shared MySQL APT repository, keeping the components
# already enabled by other modules, then refreshes the package index. The key
# and source file are created only when the repository does not exist yet;
# otherwise only the Components line is rewritten.
#
# Parameters:
#   canonical_id - Canonical module ID used for logging.
#   component - Repository component to enable (e.g. mysql-8.4-lts, mysql-tools).
#   replace - 1 to drop the enabled server series components (anything other
#             than mysql-tools) before adding the component. Default: 0.
#
# Return:
#   1 - The Ubuntu codename could not be resolved or repository setup failed.
#
add_mysql_repository_component() {
    local canonical_id="$1"
    local component="$2"
    local replace="${3:-0}"
    local codename
    local item
    local -a current=()
    local -a components=()

    read -r -a current <<<"$(__mysql_repository_components)"

    for item in "${current[@]}"; do
        if [[ "$item" == "$component" ]]; then
            continue
        fi

        if (( replace )) && [[ "$item" != "mysql-tools" ]]; then
            continue
        fi

        components+=("$item")
    done

    components+=("$component")

    if [[ -f "$__MYSQL_SOURCE_FILE" ]]; then
        __mysql_set_repository_components "$canonical_id" "${components[*]}"

        return $?
    fi

    codename="$(get_ubuntu_codename)" || return $?

    install_asc_key \
        "$canonical_id" \
        "$__MYSQL_KEY_URL" \
        "$__MYSQL_REPO_URI" \
        "$codename" \
        "${components[*]}" \
        "$__MYSQL_REPO_NAME"
}

##
# remove_mysql_repository_component <canonical_id> <component>...
#
# Removes components from the shared MySQL APT repository. The repository
# files are deleted when no component remains. Only acts when PURGE=true;
# otherwise the repository is kept.
#
# Parameters:
#   canonical_id - Canonical module ID used for logging.
#   component - One or more repository components to remove; components that
#               are not enabled are ignored.
#
# Return:
#   1 - The repository files or package lists could not be updated.
#
remove_mysql_repository_component() {
    local canonical_id="$1"
    shift

    local tag="remove-apt:$canonical_id"
    local item
    local removed
    local -a current=()
    local -a remaining=()

    if [[ "${PURGE:-false}" != "true" ]]; then
        tlog_info "$tag" "Keeping MySQL APT repository (use mp purge to remove it)"

        return 0
    fi

    read -r -a current <<<"$(__mysql_repository_components)"

    for item in "${current[@]}"; do
        for removed in "$@"; do
            if [[ "$item" == "$removed" ]]; then
                continue 2
            fi
        done

        remaining+=("$item")
    done

    if (( ${#remaining[@]} == ${#current[@]} )); then
        tlog_info "$tag" "MySQL APT repository has no matching component: %s" "$*"

        return 0
    fi

    if (( ${#remaining[@]} == 0 )); then
        remove_apt_repository "$canonical_id" "$__MYSQL_REPO_NAME"

        return $?
    fi

    __mysql_set_repository_components "$canonical_id" "${remaining[*]}"
}
