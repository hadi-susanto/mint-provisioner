#!/usr/bin/env bash

source "${LIB_DIR}/common.sh"

#
# add_ppa <module> <repository>
#
# Adds a PPA repository and refreshes the local APT package index.
# Existing configuration is left to add-apt-repository (overwrite behavior).
#
# Parameters:
#   module       Logical module or component name used for logging.
#   repository   PPA repository identifier (e.g. "ppa:git-core/ppa").
#
# Returns:
#   0            Repository added and package list updated successfully.
#   Non-zero     An error occurred.
#
# Requirements:
#   - add-apt-repository
#   - apt-get
#   - sudo privileges
#   - log_info()
#   - log_error()
#
add_ppa() {
    local module="$1"
    local repository="$2"

    if [[ -z "$module" ]]; then
        log_error "[add_ppa] Missing module parameter"

        return 1
    fi

    if [[ -z "$repository" ]]; then
        log_error "[add_ppa] [$module] Missing repository parameter"

        return 1
    fi

    log_info "[add_ppa] [$module] Adding PPA repository: $repository"

    if ! sudo add-apt-repository -y "$repository"; then
        log_error "[add_ppa] [$module] Failed to add PPA repository: $repository"

        return 1
    fi

    log_info "[add_ppa] [$module] Updating package list(s)"

    if ! sudo apt-get update; then
        log_error "[add_ppa] [$module] Failed to update package list(s)"

        return 1
    fi

    return 0
}

#
# install_asc_key <module> <asc_url> <uri> <suite> <components>
#
# Downloads an ASCII-armored GPG signing key, installs it into the APT
# keyring directory, recreates the repository source definition, and
# refreshes the local package index.
#
# Parameters:
#   module       Repository identifier used for generated file names.
#   asc_url      URL of the repository ASC signing key.
#   uri          Repository URI.
#   suite        Repository suite/distribution.
#   components   Repository components.
#
# Generated Files:
#   /etc/apt/keyrings/<module>.gpg
#   /etc/apt/sources.list.d/<module>.sources
#
# Behavior:
#   1. Validates all required parameters.
#   2. Creates the APT keyring directory if necessary.
#   3. Removes any existing keyring and source files for the module.
#   4. Downloads and installs the repository signing key.
#   5. Creates a deb822 repository source definition.
#   6. Updates the local APT package cache.
#
# Notes:
#   - Existing configuration is always replaced.
#   - The function is intentionally idempotent; repeated executions
#     produce the same repository configuration.
#   - Assumes 'set -o pipefail' is enabled by the caller.
#
# Returns:
#   0            Repository configured successfully.
#   Non-zero     An error occurred.
#
install_asc_key() {
    local module="$1"
    local asc_url="$2"
    local uri="$3"
    local suite="$4"
    local components="$5"

    if [[ -z "$module" ]]; then
        log_error "[install_asc_key] Missing module parameter"

        return 1
    fi

    if [[ -z "$asc_url" ]]; then
        log_error "[install_asc_key] [$module] Missing ASC key URL"

        return 1
    fi

    if [[ -z "$uri" ]]; then
        log_error "[install_asc_key] [$module] Missing repository URI"

        return 1
    fi

    if [[ -z "$suite" ]]; then
        log_error "[install_asc_key] [$module] Missing repository suite"

        return 1
    fi

    local keyring_dir="/etc/apt/keyrings"
    local keyring_file="${keyring_dir}/${module}.gpg"
    local source_file="/etc/apt/sources.list.d/${module}.sources"
    local arch

    if ! arch="$(dpkg --print-architecture)"; then
        log_error "[install_asc_key] [$module] Failed to determine system architecture"

        return 1
    fi

    log_info "[install_asc_key] [$module] Preparing APT keyring directory"

    if ! sudo mkdir -p "$keyring_dir"; then
        log_error "[install_asc_key] [$module] Failed to create keyring directory"

        return 1
    fi

    if [[ -f "$source_file" ]]; then
        log_warn "[install_asc_key] [$module] Removing existing source file: $source_file"

        if ! sudo rm -f "$source_file"; then
            log_error "[install_asc_key] [$module] Failed to remove source file"

            return 1
        fi
    fi

    if [[ -f "$keyring_file" ]]; then
        log_warn "[install_asc_key] [$module] Removing existing keyring: $keyring_file"

        if ! sudo rm -f "$keyring_file"; then
            log_error "[install_asc_key] [$module] Failed to remove keyring"

            return 1
        fi
    fi

    log_info "[install_asc_key] [$module] Downloading ASC key from: $asc_url"

    if ! curl -fsSL "$asc_url" | sudo gpg --dearmor -o "$keyring_file"; then
        log_error "[install_asc_key] [$module] Failed to download or install signing key"

        return 1
    fi

    log_info "[install_asc_key] [$module] Creating source file: $source_file"

    if ! sudo tee "$source_file" >/dev/null <<EOF
Types: deb
URIs: ${uri}
Suites: ${suite}
Components: ${components}
Signed-By: ${keyring_file}
Architectures: ${arch}
EOF
    then
        log_error "[install_asc_key] [$module] Failed to create source file"

        return 1
    fi

    log_info "[install_asc_key] [$module] Repository configuration completed"
    log_info "[install_asc_key] [$module] Updating package list(s)"

    if ! sudo apt-get update; then
        log_error "[install_asc_key] [$module] Failed to update package list(s)"

        return 1
    fi

    return 0
}

#
# apt_install <package...>
#
# Installs one or more APT packages using apt-fast (if available)
# or apt-get as fallback, with retry support.
#
# Behavior:
#   - Uses apt-fast if available, otherwise apt-get.
#   - Retries installation up to 3 times on failure.
#   - Fails immediately after final unsuccessful attempt.
#   - Requires at least one package argument.
#
# Returns:
#   0            Success
#   1            Failure (after retries or invalid input)
#
apt_install() {
    local apt_command
    local attempt
    local max_attempts=3

    # 1) Validate input
    if [[ "$#" -eq 0 ]]; then
        log_error "[apt_install] No package specified"

        return 1
    fi

    # Choose backend
    if command -v apt-fast >/dev/null 2>&1; then
        apt_command="apt-fast"
    else
        apt_command="apt-get"
    fi

    log_info "[apt_install] [$apt_command] Installing packages: $*"

    # 4) Retry loop (up to 3 times)
    for ((attempt = 1; attempt <= max_attempts; attempt++)); do
        if sudo "$apt_command" install -y "$@"; then
            log_info "[apt_install] [$apt_command] Installation successful"

            return 0
        fi

        log_error "[apt_install] [$apt_command] Attempt $attempt failed for packages: $*"

        if [[ "$attempt" -lt "$max_attempts" ]]; then
            log_info "[apt_install] [$apt_command] Retrying installation (attempt $((attempt + 1))/$max_attempts)"
        fi
    done

    log_error "[apt_install] [$apt_command] Installation failed after $max_attempts attempts: $*"

    return 1
}
