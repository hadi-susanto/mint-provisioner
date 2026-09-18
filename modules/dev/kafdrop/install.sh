#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/messages.sh"
source "$LIB_INSTALLER/path.sh"
source "$LIB_INSTALLER/registry.sh"
source "$LIB_INSTALLER/state.sh"
source "$LIB_INSTALLER/symlink.sh"

__install_binary() {
    local install_path="$1"
    local tag="install:$CANONICAL_ID"
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

__write_executable_wrapper() {
    local install_path="$1"
    local tag="exec-wrapper:$CANONICAL_ID"

    local wrapper_source="$MP_MODULES/$CANONICAL_ID/payload/kafdrop"
    local wrapper_file="$install_path/kafdrop"
    local jar_files=()

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

    local jar_file
    jar_file="$(realpath "${jar_files[0]}")"

    if ! install -m 755 "$wrapper_source" "$wrapper_file"; then
        tlog_error "$tag" "Failed to install wrapper to $wrapper_file"

        return 1
    fi

    # Escape characters special to sed's replacement string.
    local escaped_jar_file
    escaped_jar_file="${jar_file//\\/\\\\}"
    escaped_jar_file="${escaped_jar_file//&/\\&}"
    escaped_jar_file="${escaped_jar_file//|/\\|}"

    if ! sed -i \
        "s|KAFDROP_BINARY_FILE|$escaped_jar_file|g" \
        "$wrapper_file"; then
        tlog_error "$tag" "Failed to configure wrapper $wrapper_file"

        return 1
    fi

    symlink_binary "$CANONICAL_ID" "$wrapper_file"
}

main() {
    local install_path

    load_states "$CANONICAL_ID" || return 1
    install_path="$(expand_path "${KAFDROP_INSTALL_DIR:-$INSTALL_DIR/kafdrop}")" || return $?

    __install_binary "$install_path"
    __write_executable_wrapper "$install_path"

    save_registry "$CANONICAL_ID" || return $?

    if command -v java >/dev/null 2>&1; then
        return 0
    fi

    add_message "$CANONICAL_ID" "warn" "Java is required to run Kafdrop, please install one."
}

main