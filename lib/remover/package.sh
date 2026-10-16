#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_REMOVER_PACKAGE_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_REMOVER_PACKAGE_LOADED=1

source "$LIB_COMMON/common.sh"

##
# __package_removable <package> <purge>
#
# Succeeds when the package is installed, or, in purge mode, when only its
# configuration files remain.
#
__package_removable() {
    local package="$1"
    local purge="$2"
    local status

    if ! status="$(dpkg-query --show --showformat='${Status}' "$package" 2>/dev/null)"; then
        return 1
    fi

    if [[ "$status" == "install ok installed" ]]; then
        return 0
    fi

    if (( purge )) && [[ "$status" == *" config-files" ]]; then
        return 0
    fi

    return 1
}

##
# package_remove
#
# Removes Debian packages installed from native sources, APT repositories, or
# .deb files. Uses `apt-get purge` when PURGE=true and `apt-get remove` otherwise.
# Packages that are not installed are skipped. Dependencies are not autoremoved.
#
# Parameters:
#   canonical_id - Canonical module ID used for logging.
#   package - One or more package names (not .deb file paths).
#
# Return:
#   0 - The packages were removed or none needed removal.
#   1 - Validation failed or apt-get failed.
#
package_remove() {
    local canonical_id="${1:-}"
    local tag="remove-package"

    if [[ -n "$canonical_id" ]]; then
        tag+=":$canonical_id"
    fi

    if (( $# < 2 )) || [[ -z "$canonical_id" ]]; then
        tlog_error "$tag" "A canonical ID and at least one package are required"

        return 1
    fi

    shift

    local action="remove"
    local purge=0
    local package
    local -a targets=()

    if [[ "${PURGE:-false}" == "true" ]]; then
        action="purge"
        purge=1
    fi

    for package in "$@"; do
        if [[ -z "$package" ]]; then
            tlog_error "$tag" "Package names must not be empty"

            return 1
        fi
    done

    for package in "$@"; do
        if __package_removable "$package" "$purge"; then
            targets+=("$package")
        else
            tlog_info "$tag" "Package is not installed, skipping: %s" "$package"
        fi
    done

    if (( ${#targets[@]} == 0 )); then
        tlog_info "$tag" "No packages require %s" "$action"

        return 0
    fi

    tlog_info "$tag" "Running apt-get %s: %s" "$action" "${targets[*]}"

    if ! sudo apt-get "$action" -y "${targets[@]}"; then
        tlog_error "$tag" "Failed to %s packages: %s" "$action" "${targets[*]}"

        return 1
    fi

    return 0
}
