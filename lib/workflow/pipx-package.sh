#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_PIPX_PACKAGE_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_PIPX_PACKAGE_LOADED=1

source "$LIB_COMMON/common.sh"

##
# pypi_latest_version <canonical_id> <package>
#
# Resolves the latest release of a package from PyPI.
#
# Parameters:
#   canonical_id - Canonical module ID used for logging.
#   package - PyPI package name.
#
# Output:
#   Prints the latest version.
#
# Return:
#   1 - The lookup failed or returned an unexpected value.
#
pypi_latest_version() {
    local canonical_id="$1"
    local package="$2"
    local tag="latest:$canonical_id"
    local response
    local version

    if ! response="$(curl -fsSL "https://pypi.org/pypi/$package/json")"; then
        tlog_error "$tag" "Failed to query the latest %s version from PyPI" "$package"

        return 1
    fi

    if command -v jq >/dev/null 2>&1; then
        version="$(jq -r '.info.version // empty' <<<"$response" 2>/dev/null || true)"
    else
        # Without jq, rely on info.version being the first "version" key in the response.
        version="$(grep -o -m 1 '"version": *"[^"]*"' <<<"$response" | head -n 1 || true)"
        version="${version%\"}"
        version="${version##*\"}"
    fi

    if [[ ! "$version" =~ ^[0-9]+(\.[0-9A-Za-z]+)+$ ]]; then
        tlog_error "$tag" "Failed to determine the latest %s version" "$package"

        return 1
    fi

    printf '%s\n' "$version"
}

##
# pipx_package_binary <install_path> <package> <binary>
#
# Parameters:
#   install_path - pipx home (PIPX_HOME).
#   package - Package name, which names the venv.
#   binary - Executable name inside the venv.
#
# Output:
#   Prints the executable path inside the pipx home.
#
pipx_package_binary() {
    printf '%s\n' "$1/venvs/$2/bin/$3"
}

##
# pipx_package_install <canonical_id> <install_path> <package> <binary> <version> [<extras>]
#
# Installs or replaces a package with pipx (pipx install --force) in the pipx
# home install_path. Other venvs in the pipx home are not touched.
#
# Parameters:
#   canonical_id - Canonical module ID used for logging.
#   install_path - pipx home (PIPX_HOME).
#   package - PyPI package name.
#   binary - Executable name expected inside the venv.
#   version - Package version to install.
#   extras - Optional comma-separated extras, such as "gui"; the venv keeps the package name.
#
# Return:
#   1 - The directory could not be created, pipx failed, or the executable is missing.
#
pipx_package_install() {
    local canonical_id="$1"
    local install_path="$2"
    local package="$3"
    local binary="$4"
    local version="$5"
    local extras="${6:-}"
    local tag="pipx:$canonical_id"
    local executable
    local requirement="$package"

    executable="$(pipx_package_binary "$install_path" "$package" "$binary")"

    if [[ -n "$extras" ]]; then
        requirement+="[$extras]"
    fi

    if ! mkdir -p "$install_path"; then
        tlog_error "$tag" "Failed to create installation directory: %s" "$install_path"

        return 1
    fi

    tlog_info "$tag" "Installing %s %s with pipx into %s" "$package" "$version" "$install_path"
    if ! PIPX_HOME="$install_path" pipx install --force "$requirement==$version"; then
        tlog_error "$tag" "pipx failed to install %s" "$package"

        return 1
    fi

    if [[ ! -x "$executable" ]]; then
        tlog_error "$tag" "Expected executable not found: %s" "$executable"

        return 1
    fi
}

##
# pipx_package_uninstall <canonical_id> <install_path> <package>
#
# Uninstalls one package from the pipx home with pipx uninstall. Other venvs in
# the pipx home are kept. A package that is not installed is not an error.
#
# Parameters:
#   canonical_id - Canonical module ID used for logging.
#   install_path - pipx home (PIPX_HOME).
#   package - Package name, which names the venv.
#
# Return:
#   1 - pipx is missing while the venv exists, or pipx failed.
#
pipx_package_uninstall() {
    local canonical_id="$1"
    local install_path="$2"
    local package="$3"
    local tag="pipx:$canonical_id"

    if [[ ! -d "$install_path/venvs/$package" ]]; then
        tlog_info "$tag" "%s is not installed in %s, skipping" "$package" "$install_path"

        return 0
    fi

    if ! command -v pipx >/dev/null 2>&1; then
        tlog_error "$tag" "pipx is required to uninstall %s" "$package"

        return 1
    fi

    if ! PIPX_HOME="$install_path" pipx uninstall "$package"; then
        tlog_error "$tag" "pipx failed to uninstall %s" "$package"

        return 1
    fi
}
