#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_APT_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_APT_LOADED=1

source "$LIB_COMMON/common.sh"

##
# add_ppa
#
# Adds a Launchpad PPA and refreshes the APT package index.
#
# Parameters:
#   canonical_id - Canonical module ID used for logging.
#   repository - Launchpad PPA identifier to add.
#
# Return:
#   0 - The PPA was added and the package index was refreshed.
#   1 - Validation, repository addition, or index refresh failed.
#
add_ppa() {
    local canonical_id="${1:-}"
    local repository="${2:-}"
    local tag="ppa"

    if [[ -n "$canonical_id" ]]; then
        tag+=":$canonical_id"
    fi

    if (( $# != 2 )) || [[ -z "$canonical_id" || -z "$repository" ]]; then
        tlog_error "$tag" "A canonical ID and PPA repository are required"

        return 1
    fi

    tlog_info "$tag" "Adding PPA repository: %s" "$repository"

    if ! sudo add-apt-repository -y "$repository"; then
        tlog_error "$tag" "Failed to add PPA repository: %s" "$repository"

        return 1
    fi

    tlog_info "$tag" "Updating package lists"

    if ! sudo apt-get update; then
        tlog_error "$tag" "Failed to update package lists"

        return 1
    fi

    return 0
}

##
# install_asc_key
#
# Installs an APT signing key and deb822 repository definition, then refreshes
# the package index.
#
# Parameters:
#   canonical_id - Canonical module ID used for logging and the default filename.
#   key_url - URL of the repository signing key.
#   uri - Base URI of the APT repository.
#   suite - Distribution suite published by the repository.
#   components - Space-separated repository components.
#   filename - Optional keyring and source filename without an extension.
#
# Return:
#   0 - The signing key and repository definition were installed.
#   1 - Validation, repository setup, or package-index refresh failed.
#
install_asc_key() {
    local canonical_id="${1:-}"
    local key_url="${2:-}"
    local uri="${3:-}"
    local suite="${4:-}"
    local components="${5:-}"
    local filename="${6:-$canonical_id}"
    local tag="asc"

    if [[ -n "$canonical_id" ]]; then
        tag+=":$canonical_id"
    fi

    if (( $# < 5 || $# > 6 )) ||
        [[ -z "$canonical_id" || -z "$key_url" || -z "$uri" ||
            -z "$suite" || -z "$components" || -z "$filename" ]]; then
        tlog_error "$tag" "Invalid APT repository arguments"

        return 1
    fi

    local normalized_filename="${filename//\//_}"
    local keyring_dir="/etc/apt/keyrings"
    local keyring_file="$keyring_dir/$normalized_filename.gpg"
    local source_dir="/etc/apt/sources.list.d"
    local source_file="$source_dir/$normalized_filename.sources"
    local architecture
    local temporary_key

    if ! architecture="$(dpkg --print-architecture)"; then
        tlog_error "$tag" "Failed to determine the system architecture"

        return 1
    fi

    if [[ "$normalized_filename" == .* || "$normalized_filename" == *..* ||
        ! "$normalized_filename" =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*$ ]]; then
        tlog_error "$tag" "Invalid APT repository filename: %s" "$filename"

        return 1
    fi

    if ! sudo mkdir -p "$keyring_dir" "$source_dir"; then
        tlog_error "$tag" "Failed to prepare APT repository directories"

        return 1
    fi

    if [[ -f "$source_file" ]] && ! sudo rm -f "$source_file"; then
        tlog_error "$tag" "Failed to replace source definition: %s" "$source_file"

        return 1
    fi

    if [[ -f "$keyring_file" ]] && ! sudo rm -f "$keyring_file"; then
        tlog_error "$tag" "Failed to replace signing key: %s" "$keyring_file"

        return 1
    fi

    tlog_info "$tag" "Installing signing key from: %s" "$key_url"

    if ! temporary_key="$(mktemp)"; then
        tlog_error "$tag" "Failed to create a temporary signing-key file"

        return 1
    fi

    if ! curl -fsSL -o "$temporary_key" "$key_url"; then
        rm -f "$temporary_key"
        tlog_error "$tag" "Failed to download the signing key"

        return 1
    fi

    if ! sudo gpg --dearmor -o "$keyring_file" <"$temporary_key"; then
        rm -f "$temporary_key"
        tlog_error "$tag" "Failed to install the signing key"

        return 1
    fi

    rm -f "$temporary_key"

    tlog_info "$tag" "Creating source definition: %s" "$source_file"

    if ! sudo tee "$source_file" >/dev/null <<EOF
Types: deb
URIs: ${uri}
Suites: ${suite}
Components: ${components}
Signed-By: ${keyring_file}
Architectures: ${architecture}
EOF
    then
        tlog_error "$tag" "Failed to create source definition"

        return 1
    fi

    if ! sudo apt-get update; then
        tlog_error "$tag" "Failed to update package lists"

        return 1
    fi

    return 0
}

__restore_apt_int_trap() {
    local previous_int_trap="$1"

    if [[ -n "$previous_int_trap" ]]; then
        eval "$previous_int_trap"

        return 0
    fi

    trap - INT
}

##
# apt_install
#
# Installs packages with apt-fast when available, otherwise apt-get, using up
# to three attempts.
#
# Parameters:
#   canonical_id - Canonical module ID used for logging.
#   package - One or more package names to install.
#
# Return:
#   0 - All requested packages were installed.
#   1 - Validation failed or all installation attempts failed.
#   130 - Package installation was interrupted.
#
apt_install() {
    local canonical_id="${1:-}"
    local tag="apt"

    if [[ -n "$canonical_id" ]]; then
        tag+=":$canonical_id"
    fi

    if (( $# < 2 )) || [[ -z "$canonical_id" ]]; then
        tlog_error "$tag" "A canonical ID and at least one package are required"

        return 1
    fi

    shift

    local package

    for package in "$@"; do
        if [[ -z "$package" ]]; then
            tlog_error "$tag" "Package names must not be empty"

            return 1
        fi
    done

    local apt_command="apt-get"
    local attempt
    local interrupted=0
    local max_attempts=3
    local previous_int_trap

    if command -v apt-fast >/dev/null 2>&1; then
        apt_command="apt-fast"
    fi

    tlog_info "$tag" "Installing packages with %s: %s" "$apt_command" "$*"

    previous_int_trap="$(trap -p INT)"
    trap 'interrupted=1' INT

    for (( attempt = 1; attempt <= max_attempts; attempt += 1 )); do
        if sudo "$apt_command" install -y "$@"; then
            __restore_apt_int_trap "$previous_int_trap"
            tlog_info "$tag" "Package installation completed"

            return 0
        fi

        if (( interrupted )); then
            __restore_apt_int_trap "$previous_int_trap"
            tlog_warn "$tag" "Package installation interrupted"

            return 130
        fi

        tlog_error "$tag" "Installation attempt %d/%d failed" \
            "$attempt" "$max_attempts"
    done

    __restore_apt_int_trap "$previous_int_trap"
    tlog_error "$tag" "Package installation failed after %d attempts" "$max_attempts"

    return 1
}
