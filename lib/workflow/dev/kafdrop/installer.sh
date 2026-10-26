#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_KAFDROP_INSTALLER_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_KAFDROP_INSTALLER_LOADED=1

source "$LIB_COMMON/common.sh"
source "$LIB_INSTALLER/registry.sh"
source "$LIB_INSTALLER/state.sh"

##
# kafdrop_install_jar <canonical_id> <install_path>
#
# Copies the downloaded jar from the BINARY_FILE state into install_path as
# kafdrop-<KAFDROP_VERSION>.jar and sets the INSTALL_PATH and KAFDROP_VERSION
# registry values in memory. States must already be loaded.
#
# Parameters:
#   canonical_id - Canonical module ID used for logging.
#   install_path - Kafdrop installation directory.
#
# Return:
#   1 - A state is missing or the jar could not be copied.
#
kafdrop_install_jar() {
    local canonical_id="$1"
    local install_path="$2"
    local tag="install:$canonical_id"
    local binary_file
    local kafdrop_version

    tlog_info "$tag" "Installing Kafdrop to: %s" "$install_path"
    binary_file="$(get_state "BINARY_FILE")" || return $?
    kafdrop_version="$(get_state "KAFDROP_VERSION")" || return $?
    if [[ ! -f "$binary_file" ]]; then
        tlog_error "$tag" "Kafdrop binary not found: %s" "$binary_file"

        return 1
    fi
    if ! mkdir -p "$install_path"; then
        tlog_error "$tag" "Failed to create install directory: %s" "$install_path"

        return 1
    fi
    if ! cp "$binary_file" "$install_path/kafdrop-${kafdrop_version}.jar"; then
        tlog_error "$tag" "Failed to copy %s to %s" "$binary_file" "$install_path"

        return 1
    fi

    set_registry "INSTALL_PATH" "$install_path" || return $?
    set_registry "KAFDROP_VERSION" "$kafdrop_version" || return $?

    return 0
}

##
# kafdrop_write_wrapper <canonical_id> <install_path>
#
# Installs the kafdrop wrapper script into install_path, pointing it at the
# single kafdrop jar in that directory.
#
# Parameters:
#   canonical_id - Canonical module ID selecting the wrapper payload.
#   install_path - Kafdrop installation directory.
#
# Return:
#   1 - No jar or more than one jar exists, or the wrapper could not be written.
#
kafdrop_write_wrapper() {
    local canonical_id="$1"
    local install_path="$2"
    local tag="exec-wrapper:$canonical_id"
    local wrapper_source="$MP_MODULES/$canonical_id/payload/kafdrop"
    local wrapper_file="$install_path/kafdrop"
    local -a jar_files=()
    local jar_file
    local escaped_jar_file

    mapfile -t jar_files < <(
        find "$install_path" -maxdepth 1 -type f -name '*.jar' -print
    )

    if (( ${#jar_files[@]} == 0 )); then
        tlog_error "$tag" "No JAR file found in $install_path"

        return 1
    fi

    if (( ${#jar_files[@]} > 1 )); then
        tlog_error "$tag" "Multiple JAR files found in $install_path"

        return 1
    fi

    jar_file="$(realpath "${jar_files[0]}")"

    if ! install -m 755 "$wrapper_source" "$wrapper_file"; then
        tlog_error "$tag" "Failed to install wrapper to $wrapper_file"

        return 1
    fi

    # Escape characters special to sed's replacement string.
    escaped_jar_file="${jar_file//\\/\\\\}"
    escaped_jar_file="${escaped_jar_file//&/\\&}"
    escaped_jar_file="${escaped_jar_file//|/\\|}"

    if ! sed -i \
        "s|KAFDROP_BINARY_FILE|$escaped_jar_file|g" \
        "$wrapper_file"; then
        tlog_error "$tag" "Failed to configure wrapper $wrapper_file"

        return 1
    fi
}
