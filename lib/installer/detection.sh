#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_DETECTION_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_DETECTION_LOADED=1

source "$LIB_COMMON/common.sh"
source "$LIB_COMMON/script.sh"

##
# package_installed
#
# Checks whether any supplied Debian package is installed.
#
# Parameters:
#   canonical_id - Canonical module ID used for error logging.
#   package - One or more Debian package names to check.
#
# Return:
#   0 - At least one supplied package is installed.
#   1 - None of the supplied packages are installed.
#   2 - Input is invalid or a package query failed unexpectedly.
#
package_installed() {
    local canonical_id="${1:-}"
    local tag="detection"

    if [[ -n "$canonical_id" ]]; then
        tag+=":$canonical_id"
    fi

    if (( $# < 2 )) || [[ -z "$canonical_id" ]]; then
        tlog_error "$tag" "A canonical ID and at least one package are required"

        return 2
    fi

    shift

    local package
    local package_status
    local status

    for package in "$@"; do
        if [[ -z "$package" ]]; then
            tlog_error "$tag" "A package name must not be empty"

            return 2
        fi

        if package_status="$(
            dpkg-query \
                --show \
                --showformat='${Status}' \
                "$package" 2>/dev/null
        )"; then
            if [[ "$package_status" == "install ok installed" ]]; then
                return 0
            fi

            continue
        else
            status=$?
        fi

        if (( status == 1 )); then
            continue
        fi

        tlog_error "$tag" "Failed to query package status for %s (status: %d)" \
            "$package" "$status"

        return 2
    done

    return 1
}

##
# module_installed
#
# Determines a module's installed state using its custom detector or CLI.
#
# Parameters:
#   canonical_id - Canonical module ID.
#   metadata_name - Name of the associative array containing module metadata.
#
# Return:
#   0 - The module is installed.
#   1 - The module is not installed.
#   2 - Input is invalid or the installation state cannot be determined.
#   Other - The custom detector's non-zero status is preserved.
#
module_installed() {
    local canonical_id="${1:-}"
    local metadata_name="${2:-}"
    local tag="detection"

    if [[ -n "$canonical_id" ]]; then
        tag+=":$canonical_id"
    fi

    if (( $# != 2 )) || [[ -z "$canonical_id" ]] ||
        [[ ! "$metadata_name" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
        tlog_error "$tag" "A canonical ID and metadata array are required"

        return 2
    fi

    local -n metadata_ref="$metadata_name"
    local module_dir="$MP_MODULES/$canonical_id"
    local installed_script="$module_dir/installed.sh"
    local cli
    local command_name
    local status
    local -a commands=()

    if [[ ! -d "$module_dir" ]] || [[ -L "$module_dir" ]]; then
        tlog_error "$tag" "Invalid module directory: %s" "$module_dir"

        return 2
    fi

    if [[ -L "$installed_script" ]]; then
    tlog_error "$tag" \
        "Installed-state script must not be a symbolic link: %s" \
        "$installed_script"

    return 2
fi

    if [[ -e "$installed_script" ]] && [[ ! -f "$installed_script" ]]; then
        tlog_error "$tag" "Invalid installed-state script: %s" \
            "$installed_script"

        return 2
    fi

    if [[ -f "$installed_script" ]]; then
        if run_script "$installed_script" "CANONICAL_ID" "$canonical_id"; then
            return 0
        else
            status=$?
        fi

        return "$status"
    fi

    cli="${metadata_ref[CLI]:-}"
    if [[ -z "$cli" ]]; then
        cli="${canonical_id##*/}"
    fi

    if [[ "$cli" == ,* ]] || [[ "$cli" == *, ]]; then
        tlog_error "$tag" "CLI metadata contains an empty command"

        return 2
    fi

    IFS=',' read -r -a commands <<< "$cli"

    for command_name in "${commands[@]}"; do
        __trim command_name
        if [[ -z "$command_name" ]]; then
            tlog_error "$tag" "CLI metadata contains an empty command"

            return 2
        fi

        if ! command -v "$command_name" >/dev/null 2>&1; then
            return 1
        fi
    done

    return 0
}
