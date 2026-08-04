#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_DISTRO_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_DISTRO_LOADED=1

source "$LIB_COMMON/common.sh"

__DISTRO_OS_RELEASE_FILE="${__DISTRO_OS_RELEASE_FILE:-/etc/os-release}"
__DISTRO_UPSTREAM_RELEASE_FILE="${__DISTRO_UPSTREAM_RELEASE_FILE:-/etc/upstream-release/lsb-release}"
__DISTRO_RELEASE_LOADED=0
__DISTRO_UBUNTU_VERSION=''
__DISTRO_UBUNTU_CODENAME=''

__read_release_value() {
    local file="$1"
    local key="$2"
    local result_name="$3"
    local -n result_ref="$result_name"

    result_ref=''
    [[ -f "$file" ]] || return 1

    result_ref="$({
        (
            # Release files are shell-compatible assignments. Source them in
            # a subshell so they cannot modify the caller's environment.
            source "$file"
            if [[ -v "$key" ]]; then
                printf '%s' "${!key}"
            fi
        )
    })" || return 1
}

__ubuntu_version_for_codename() {
    case "$1" in
        resolute) printf '%s\n' '26.04' ;;
        questing) printf '%s\n' '25.10' ;;
        plucky) printf '%s\n' '25.04' ;;
        oracular) printf '%s\n' '24.10' ;;
        noble) printf '%s\n' '24.04' ;;
        mantic) printf '%s\n' '23.10' ;;
        lunar) printf '%s\n' '23.04' ;;
        kinetic) printf '%s\n' '22.10' ;;
        jammy) printf '%s\n' '22.04' ;;
        impish) printf '%s\n' '21.10' ;;
        hirsute) printf '%s\n' '21.04' ;;
        groovy) printf '%s\n' '20.10' ;;
        focal) printf '%s\n' '20.04' ;;
        eoan) printf '%s\n' '19.10' ;;
        disco) printf '%s\n' '19.04' ;;
        cosmic) printf '%s\n' '18.10' ;;
        bionic) printf '%s\n' '18.04' ;;
        *) return 1 ;;
    esac
}

__ubuntu_codename_for_version() {
    case "$1" in
        26.04) printf '%s\n' 'resolute' ;;
        25.10) printf '%s\n' 'questing' ;;
        25.04) printf '%s\n' 'plucky' ;;
        24.10) printf '%s\n' 'oracular' ;;
        24.04) printf '%s\n' 'noble' ;;
        23.10) printf '%s\n' 'mantic' ;;
        23.04) printf '%s\n' 'lunar' ;;
        22.10) printf '%s\n' 'kinetic' ;;
        22.04) printf '%s\n' 'jammy' ;;
        21.10) printf '%s\n' 'impish' ;;
        21.04) printf '%s\n' 'hirsute' ;;
        20.10) printf '%s\n' 'groovy' ;;
        20.04) printf '%s\n' 'focal' ;;
        19.10) printf '%s\n' 'eoan' ;;
        19.04) printf '%s\n' 'disco' ;;
        18.10) printf '%s\n' 'cosmic' ;;
        18.04) printf '%s\n' 'bionic' ;;
        *) return 1 ;;
    esac
}

__load_ubuntu_release() {
    if (( __DISTRO_RELEASE_LOADED )); then
        return 0
    fi

    local id=''
    local id_like=''
    local version_id=''
    local version_codename=''
    local ubuntu_codename=''
    local upstream_release=''
    local upstream_codename=''
    local upstream_id=''
    local codename=''
    local version=''
    local mapped_codename=''
    local mapped_version=''

    if [[ ! -f "$__DISTRO_OS_RELEASE_FILE" ]]; then
        tlog_error "distro" "Release file not found: %s" "$__DISTRO_OS_RELEASE_FILE"

        return 1
    fi

    __read_release_value "$__DISTRO_OS_RELEASE_FILE" ID id || return 1
    __read_release_value "$__DISTRO_OS_RELEASE_FILE" ID_LIKE id_like || true
    __read_release_value "$__DISTRO_OS_RELEASE_FILE" VERSION_ID version_id || true
    __read_release_value "$__DISTRO_OS_RELEASE_FILE" VERSION_CODENAME version_codename || true
    __read_release_value "$__DISTRO_OS_RELEASE_FILE" UBUNTU_CODENAME ubuntu_codename || true

    if [[ -f "$__DISTRO_UPSTREAM_RELEASE_FILE" ]]; then
        __read_release_value \
            "$__DISTRO_UPSTREAM_RELEASE_FILE" DISTRIB_ID upstream_id || true
        __read_release_value \
            "$__DISTRO_UPSTREAM_RELEASE_FILE" DISTRIB_RELEASE upstream_release || true
        __read_release_value \
            "$__DISTRO_UPSTREAM_RELEASE_FILE" DISTRIB_CODENAME upstream_codename || true

        if [[ "${upstream_id,,}" != 'ubuntu' || -z "$upstream_release" ||
            -z "$upstream_codename" ]]; then
            tlog_error "distro" "Invalid Ubuntu upstream release information"

            return 1
        fi
    fi

    if [[ "$id" != 'ubuntu' && " $id_like " != *' ubuntu '* &&
        -z "$ubuntu_codename" && "${upstream_id,,}" != 'ubuntu' ]]; then
        tlog_error "distro" "The current distribution is not recognized as Ubuntu-based"

        return 1
    fi

    if [[ -n "$ubuntu_codename" ]]; then
        codename="$ubuntu_codename"
    elif [[ -n "$upstream_codename" ]]; then
        codename="$upstream_codename"
    elif [[ "$id" == 'ubuntu' && -n "$version_codename" ]]; then
        codename="$version_codename"
    elif mapped_version="$(__ubuntu_version_for_codename "$version_codename")"; then
        codename="$version_codename"
    elif mapped_codename="$(__ubuntu_codename_for_version "$version_id")"; then
        codename="$mapped_codename"
    fi

    if [[ ! "$codename" =~ ^[a-z][a-z0-9-]*$ ]]; then
        tlog_error "distro" "Unsupported Ubuntu codename: %s" "${codename:-<empty>}"

        return 1
    fi

    if [[ -n "$upstream_release" ]]; then
        version="$upstream_release"
    elif [[ "$id" == 'ubuntu' && -n "$version_id" ]]; then
        version="$version_id"
    elif mapped_version="$(__ubuntu_version_for_codename "$codename")"; then
        version="$mapped_version"
    fi

    if [[ ! "$version" =~ ^[0-9]{2}\.[0-9]{2}$ ]]; then
        tlog_error "distro" "Unsupported Ubuntu version: %s" "${version:-<empty>}"

        return 1
    fi

    if [[ -n "$upstream_codename" && "$upstream_codename" != "$codename" ]]; then
        tlog_error "distro" "Inconsistent Ubuntu codenames: %s and %s" \
            "$upstream_codename" "$codename"

        return 1
    fi

    if [[ "$id" == 'ubuntu' && -n "$version_codename" &&
        "$version_codename" != "$codename" ]]; then
        tlog_error "distro" "Inconsistent Ubuntu codenames: %s and %s" \
            "$version_codename" "$codename"

        return 1
    fi

    if [[ "$id" == 'ubuntu' && -n "$version_id" && "$version_id" != "$version" ]]; then
        tlog_error "distro" "Inconsistent Ubuntu version: %s (%s)" \
            "$version_id" "$codename"

        return 1
    fi

    if mapped_version="$(__ubuntu_version_for_codename "$codename")" &&
        [[ "$mapped_version" != "$version" ]]; then
        tlog_error "distro" "Inconsistent Ubuntu release: %s (%s)" \
            "$version" "$codename"

        return 1
    fi

    if mapped_codename="$(__ubuntu_codename_for_version "$version")" &&
        [[ "$mapped_codename" != "$codename" ]]; then
        tlog_error "distro" "Inconsistent Ubuntu codename: %s (%s)" \
            "$codename" "$version"

        return 1
    fi

    __DISTRO_UBUNTU_VERSION="$version"
    __DISTRO_UBUNTU_CODENAME="$codename"
    __DISTRO_RELEASE_LOADED=1

    return 0
}

##
# get_ubuntu_version
#
# Resolves the Ubuntu base version for an Ubuntu or Ubuntu-derived system.
#
# Output:
#   Prints the Ubuntu base version to standard output.
#
# Return:
#   0 - The Ubuntu base version was resolved.
#   1 - Arguments are invalid or Ubuntu release information is unavailable.
#
get_ubuntu_version() {
    if (( $# != 0 )); then
        tlog_error "distro" "get_ubuntu_version does not accept arguments"

        return 1
    fi

    __load_ubuntu_release || return $?
    printf '%s\n' "$__DISTRO_UBUNTU_VERSION"
}

##
# get_ubuntu_codename
#
# Resolves the Ubuntu base codename for an Ubuntu or Ubuntu-derived system.
#
# Output:
#   Prints the Ubuntu base codename to standard output.
#
# Return:
#   0 - The Ubuntu base codename was resolved.
#   1 - Arguments are invalid or Ubuntu release information is unavailable.
#
get_ubuntu_codename() {
    if (( $# != 0 )); then
        tlog_error "distro" "get_ubuntu_codename does not accept arguments"

        return 1
    fi

    __load_ubuntu_release || return $?
    printf '%s\n' "$__DISTRO_UBUNTU_CODENAME"
}
