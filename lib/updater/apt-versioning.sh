#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_APT_VERSIONING_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_APT_VERSIONING_LOADED=1

source "$LIB_COMMON/common.sh"

# apt-get update rewrites the partial directory on every run, unlike list files
# whose mtime follows the server and pkgcache.bin which dpkg changes also touch.
readonly -a __APT_UPDATE_STAMPS=(
    /var/lib/apt/lists/partial
    /var/lib/apt/lists
)

##
# apt_installed_version
#
# Reads the installed version of a Debian package.
#
# Parameters:
#   package - Debian package name.
#
# Output:
#   Prints the installed package version.
#
# Return:
#   1 - The package is not installed.
#   2 - The package query failed unexpectedly.
#
apt_installed_version() {
    local package="$1"
    local query
    local status

    if query="$(
        dpkg-query \
            --show \
            --showformat='${Status}\t${Version}' \
            "$package" 2>/dev/null
    )"; then
        :
    else
        status=$?
        if (( status == 1 )); then
            return 1
        fi

        tlog_error "apt-versioning" "Failed to query package %s (status: %d)" \
            "$package" "$status"

        return 2
    fi

    if [[ "${query%%$'\t'*}" != "install ok installed" ]]; then
        return 1
    fi

    printf '%s\n' "${query#*$'\t'}"
}

##
# apt_candidate_version
#
# Reads the candidate version of a Debian package from the APT cache.
#
# Parameters:
#   package - Debian package name.
#
# Output:
#   Prints the candidate package version.
#
# Return:
#   1 - The APT cache has no candidate for the package.
#   2 - The APT cache query failed.
#
apt_candidate_version() {
    local package="$1"
    local policy
    local line
    local candidate=""

    if ! policy="$(LC_ALL=C apt-cache policy "$package" 2>/dev/null)"; then
        tlog_error "apt-versioning" "Failed to query APT policy for %s" "$package"

        return 2
    fi

    while IFS= read -r line; do
        __trim line
        if [[ "$line" == Candidate:* ]]; then
            candidate="${line#Candidate:}"
            __trim candidate

            break
        fi
    done <<< "$policy"

    if [[ -z "$candidate" || "$candidate" == "(none)" ]]; then
        return 1
    fi

    printf '%s\n' "$candidate"
}

##
# apt_version_newer
#
# Compares two Debian package versions.
#
# Parameters:
#   candidate_version - Version that may be newer.
#   installed_version - Version currently installed.
#
# Return:
#   0 - candidate_version is newer than installed_version.
#   1 - candidate_version is not newer.
#
apt_version_newer() {
    local candidate_version="$1"
    local installed_version="$2"

    dpkg --compare-versions "$candidate_version" gt "$installed_version"
}

##
# apt_cache_age_days
#
# Calculates how many whole days have passed since the last APT index update.
#
# Output:
#   Prints the APT cache age in days.
#
# Return:
#   1 - No APT update timestamp could be read.
#
apt_cache_age_days() {
    local stamp
    local modified
    local now

    printf -v now '%(%s)T' -1

    for stamp in "${__APT_UPDATE_STAMPS[@]}"; do
        if modified="$(stat -c '%Y' -- "$stamp" 2>/dev/null)"; then
            printf '%d\n' "$(( (now - modified) / 86400 ))"

            return 0
        fi
    done

    return 1
}

##
# refresh_apt_cache
#
# Updates the APT package index with sudo.
#
# Return:
#   1 - The package index update failed.
#
refresh_apt_cache() {
    tlog_info "apt-versioning" "Updating package lists"

    if ! sudo apt-get update; then
        tlog_error "apt-versioning" "Failed to update package lists"

        return 1
    fi
}
