#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_VERSIONING_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_VERSIONING_LOADED=1

source "$LIB_COMMON/common.sh"
source "$LIB_COMMON/metadata.sh"
source "$LIB_UPDATER/apt-versioning.sh"
source "$LIB_INSTALLER/github.sh"
source "$LIB_UPDATER/git-versioning.sh"
source "$LIB_UPDATER/recorded-versioning.sh"
source "$LIB_WORKFLOW/latest-version.sh"

##
# __resolve_apt_versions <packages> <versions_name>
#
# Resolves versions for the first installed package of a comma-separated
# candidate list, such as "code,code-insiders".
#
__resolve_apt_versions() {
    local packages="$1"
    local -n versions_ref="$2"
    local package
    local installed
    local latest
    local status=0

    package="$(apt_installed_package "$packages")" || status=$?
    if (( status == 1 )); then
        versions_ref[NOTE]="package ${packages//,/ or } not installed via apt"

        return 0
    fi

    if (( status != 0 )) || ! installed="$(apt_installed_version "$package")"; then
        versions_ref[NOTE]="version query failed"

        return 1
    fi

    versions_ref[INSTALLED]="$installed"

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
# __resolve_recorded_versions <canonical_id> <latest> <versions_name>
#
# Compares the VERSION recorded in the module registry with the latest
# version. A missing record counts as an available update.
#
__resolve_recorded_versions() {
    local canonical_id="$1"
    local latest="$2"
    local -n versions_ref="$3"
    local installed
    local status=0

    versions_ref[LATEST]="$latest"

    installed="$(recorded_version "$canonical_id")" || status=$?
    if (( status == 1 )); then
        versions_ref[STATE]="outdated"
        versions_ref[NOTE]="update available (version not recorded)"

        return 0
    fi

    if (( status != 0 )); then
        versions_ref[NOTE]="version query failed"

        return 1
    fi

    versions_ref[INSTALLED]="$installed"

    if [[ "$installed" == "$latest" ]]; then
        versions_ref[STATE]="current"
        versions_ref[NOTE]="up to date"
    else
        versions_ref[STATE]="outdated"
        versions_ref[NOTE]="update available"
    fi
}

__resolve_github_versions() {
    local canonical_id="$1"
    local repository="$2"
    local versions_name="$3"
    local -n versions_ref="$versions_name"
    local latest

    if ! latest="$(github_latest_release_version \
        "$canonical_id" "${repository%%/*}" "${repository#*/}")"; then
        versions_ref[NOTE]="version query failed"

        return 1
    fi

    __resolve_recorded_versions "$canonical_id" "$latest" "$versions_name"
}

__resolve_external_versions() {
    local canonical_id="$1"
    local versions_name="$2"
    local -n versions_ref="$versions_name"
    local latest

    if ! latest="$(module_latest_version "$canonical_id")"; then
        versions_ref[NOTE]="version query failed"

        return 1
    fi

    __resolve_recorded_versions "$canonical_id" "$latest" "$versions_name"
}

__resolve_git_versions() {
    local canonical_id="$1"
    local -n versions_ref="$2"
    local -A commits=()
    local status=0

    git_commits "$canonical_id" commits || status=$?
    if (( status == 1 )); then
        versions_ref[NOTE]="install path not recorded"

        return 0
    fi

    if (( status != 0 )); then
        versions_ref[NOTE]="version query failed"

        return 1
    fi

    versions_ref[INSTALLED]="${commits[INSTALLED]:0:7}"
    versions_ref[LATEST]="${commits[LATEST]:0:7}"

    if [[ "${commits[INSTALLED]}" == "${commits[LATEST]}" ]]; then
        versions_ref[STATE]="current"
        versions_ref[NOTE]="up to date"
    else
        versions_ref[STATE]="outdated"
        versions_ref[NOTE]="update available"
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
#                   unknown, unsupported, or untracked (UPDATE_MODE=none).
#                   Unresolved versions are empty.
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
        github)
            __resolve_github_versions \
                "$canonical_id" "${metadata_ref[UPDATE_REPOSITORY]}" "$versions_name" || return $?
            ;;
        external)
            __resolve_external_versions "$canonical_id" "$versions_name" || return $?
            ;;
        git)
            __resolve_git_versions "$canonical_id" "$versions_name" || return $?
            ;;
        none)
            versions_ref=([INSTALLED]="-" [LATEST]="-" [STATE]="untracked" [NOTE]="version not tracked")
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

##
# uses_update_mode
#
# Checks whether any of the given modules declares an UPDATE_MODE.
#
# Parameters:
#   update_mode - UPDATE_MODE value to look for, such as apt.
#   canonical_id - One or more canonical module IDs.
#
# Return:
#   0 - At least one module uses update_mode.
#   1 - No module uses update_mode.
#   Other - Module metadata could not be parsed.
#
uses_update_mode() {
    local update_mode="$1"
    shift

    local -A module_metadata=()
    local canonical_id

    for canonical_id in "$@"; do
        module_metadata=()
        parse_module_metadata "$MP_MODULES/$canonical_id" module_metadata || return $?
        if [[ "${module_metadata[UPDATE_MODE]:-}" == "$update_mode" ]]; then
            return 0
        fi
    done

    return 1
}
