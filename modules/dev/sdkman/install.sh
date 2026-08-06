#!/usr/bin/env bash
set -euo pipefail

source "$LIB_COMMON/common.sh"
source "$LIB_INSTALLER/messages.sh"
source "$LIB_INSTALLER/registry.sh"
source "$LIB_INSTALLER/state.sh"

__extract_strip_root() {
    local canonical_id="$1"
    local archive="$2"
    local destination="$3"
    local root_directory
    local temporary_directory

    if ! temporary_directory="$(mktemp -d)"; then
        tlog_error "install:$canonical_id" "Failed to create a temporary extraction directory"

        return 1
    fi

    if ! unzip -q "$archive" -d "$temporary_directory"; then
        tlog_error "install:$canonical_id" "Failed to extract archive: %s" "$archive"
        rm -rf "$temporary_directory"

        return 1
    fi

    if ! root_directory="$(
        find "$temporary_directory" -mindepth 1 -maxdepth 1 -type d -print -quit
    )" || [[ -z "$root_directory" ]]; then
        tlog_error "install:$canonical_id" "No root directory found in archive: %s" "$archive"
        rm -rf "$temporary_directory"

        return 2
    fi

    if ! cp -r "${root_directory}/." "$destination/"; then
        tlog_error "install:$canonical_id" \
            "Failed to copy extracted files into: %s" "$destination"
        rm -rf "$temporary_directory"

        return 3
    fi

    rm -rf "$temporary_directory"
}

__install_files() {
    local canonical_id="$1"
    local install_path="$2"
    local payload_config="$3/config"
    local standard_archive
    local native_archive
    local candidates_file

    standard_archive="$(get_state "STANDARD_FILE")" || return 1
    native_archive="$(get_state "NATIVE_FILE")" || return 1
    candidates_file="$(get_state "CANDIDATES_FILE")" || return 1

    tlog_info "install:$canonical_id" "Extracting the SDKMAN! standard archive"
    __extract_strip_root "$canonical_id" "$standard_archive" "$install_path" || return 3

    tlog_info "install:$canonical_id" "Extracting the SDKMAN! native archive"
    __extract_strip_root "$canonical_id" "$native_archive" "$install_path" || return 4

    if ! cp "$candidates_file" "$install_path/var/candidates"; then
        tlog_error "install:$canonical_id" "Failed to install the SDKMAN! candidates list"

        return 8
    fi

    if ! install -m 0644 -- "$payload_config" "$install_path/etc/config"; then
        tlog_error "install:$canonical_id" "Failed to install the SDKMAN! configuration"

        return 9
    fi
}

__write_sdkman_vars() {
    local canonical_id="$1"
    local install_path="$2"
    local sdkman_version
    local sdkman_native_version

    sdkman_version="$(get_state "SDKMAN_VERSION")" || return 1
    sdkman_native_version="$(get_state "SDKMAN_NATIVE_VERSION")" || return 1

    if ! printf '%s\n' "$sdkman_version" >"$install_path/var/version"; then
        tlog_error "install:$canonical_id" "Failed to write the SDKMAN! version"

        return 5
    fi

    if ! printf '%s\n' "$sdkman_native_version" >"$install_path/var/version_native"; then
        tlog_error "install:$canonical_id" "Failed to write the SDKMAN! native version"

        return 6
    fi

    if ! printf '%s\n' "linuxx64" >"$install_path/var/platform"; then
        tlog_error "install:$canonical_id" "Failed to write the SDKMAN! platform"

        return 7
    fi
}

__save_sdkman_registry() {
    local canonical_id="$1"
    local install_path="$2"
    local sdkman_native_version
    local sdkman_version

    sdkman_version="$(get_state "SDKMAN_VERSION")" || return 1
    sdkman_native_version="$(get_state "SDKMAN_NATIVE_VERSION")" || return 1

    set_registry "INSTALL_PATH" "$install_path" || return 10
    set_registry "SDKMAN_VERSION" "$sdkman_version" || return 10
    set_registry "SDKMAN_NATIVE_VERSION" "$sdkman_native_version" || return 10

    if ! save_registry "$canonical_id"; then
        tlog_error "install:$canonical_id" "Failed to save the installation registry"

        return 10
    fi
}

main() {
    local canonical_id="$1"
    local install_path="$2"
    local payload_dir="$3/$canonical_id/payload"
    local message
    local sdkman_dir_literal

    load_states "$canonical_id" || return 1

    tlog_info "install:$canonical_id" "Installing SDKMAN! to %s" "$install_path"

    if ! mkdir -p \
        "$install_path/tmp" \
        "$install_path/ext" \
        "$install_path/etc" \
        "$install_path/var" \
        "$install_path/candidates"; then
        tlog_error "install:$canonical_id" \
            "Failed to create the SDKMAN! directory structure: %s" "$install_path"

        return 2
    fi

    __install_files "$canonical_id" "$install_path" "$payload_dir" || return $?
    __write_sdkman_vars "$canonical_id" "$install_path" || return $?
    __save_sdkman_registry "$canonical_id" "$install_path" || return $?

    tlog_info "install:$canonical_id" "Installation completed successfully"

    printf -v sdkman_dir_literal '%q' "$install_path"
    message="To enable SDKMAN! through System Toolkit, run:

  SDKMAN_DIR=$sdkman_dir_literal syskit-cfg install dev/sdkman

Without System Toolkit, add the following to your shell configuration:

# >>> mint-provisioner enabling SDKMAN! >>>
export SDKMAN_DIR=$sdkman_dir_literal
if [[ -s \"\${SDKMAN_DIR}/bin/sdkman-init.sh\" ]]; then
    source \"\${SDKMAN_DIR}/bin/sdkman-init.sh\"
fi
# <<< mint-provisioner enabling SDKMAN! <<<"

    if ! add_message "$canonical_id" info "$message"; then
        tlog_warn "install:$canonical_id" "Failed to persist SDKMAN! integration guidance"
    fi
}

main "$CANONICAL_ID" "${SDKMAN_INSTALL_DIR:-$INSTALL_DIR/sdkman}" "$MP_MODULES"
