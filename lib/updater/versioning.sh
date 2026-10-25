#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_VERSIONING_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_VERSIONING_LOADED=1

source "$LIB_COMMON/common.sh"
source "$LIB_UPDATER/apt-versioning.sh"

__resolve_apt_versions() {
    local package="$1"
    local -n versions_ref="$2"
    local installed
    local latest
    local status

    if installed="$(apt_installed_version "$package")"; then
        versions_ref[INSTALLED]="$installed"
    else
        status=$?
        if (( status == 1 )); then
            versions_ref[NOTE]="package $package not installed via apt"

            return 0
        fi

        versions_ref[NOTE]="version query failed"

        return 1
    fi

    if latest="$(apt_candidate_version "$package")"; then
        versions_ref[LATEST]="$latest"
    else
        status=$?
        if (( status == 1 )); then
            versions_ref[NOTE]="no candidate in apt cache"

            return 0
        fi

        versions_ref[NOTE]="version query failed"

        return 1
    fi

    if apt_version_newer "$latest" "$installed"; then
        versions_ref[STATE]="outdated"
        versions_ref[NOTE]="update available"
    else
        versions_ref[STATE]="current"
        versions_ref[NOTE]="up to date"
    fi
}

##
# resolve_module_versions
#
# Resolves the installed and latest versions of an installed module using its
# UPDATE_MODE metadata.
#
# Parameters:
#   canonical_id - Canonical module ID.
#   metadata_name - Name of the associative array containing module metadata.
#   versions_name - Name of the associative array that receives INSTALLED,
#                   LATEST, STATE, and NOTE. STATE is one of outdated, current,
#                   unknown, or unsupported. Unresolved versions are empty.
#
# Return:
#   1 - A version query failed; STATE is unknown.
#
resolve_module_versions() {
    local canonical_id="$1"
    local metadata_name="$2"
    local versions_name="$3"
    local -n metadata_ref="$metadata_name"
    local -n versions_ref="$versions_name"

    versions_ref=(
        [INSTALLED]=""
        [LATEST]=""
        [STATE]="unknown"
        [NOTE]=""
    )

    case "${metadata_ref[UPDATE_MODE]:-}" in
        apt)
            __resolve_apt_versions "${metadata_ref[UPDATE_PACKAGE]}" "$versions_name" || return $?
            ;;
        "")
            versions_ref[STATE]="unsupported"
            versions_ref[NOTE]="UPDATE_MODE not supported yet"
            ;;
        *)
            tlog_error "versioning:$canonical_id" "Unsupported UPDATE_MODE: %s" \
                "${metadata_ref[UPDATE_MODE]}"
            versions_ref[NOTE]="unsupported UPDATE_MODE"

            return 1
            ;;
    esac
}
