#!/usr/bin/env bash
set -euo pipefail

source "$LIB_COMMON/common.sh"
source "$LIB_INSTALLER/messages.sh"
source "$LIB_INSTALLER/path.sh"
source "$LIB_INSTALLER/registry.sh"
source "$LIB_INSTALLER/state.sh"

main() {
    local canonical_id="$1"
    local raw_install_path="$2"
    local archive_file
    local install_path
    local message
    local tag="install:$canonical_id"

    load_states "$canonical_id" || return 1
    archive_file="$(get_state "ARCHIVE_FILE")" || return 1

    if [[ ! -f "$archive_file" ]]; then
        tlog_error "$tag" "Archive file not found: %s" "$archive_file"

        return 2
    fi

    install_path="$(expand_path "$raw_install_path")" || return $?
    if ! mkdir -p -- "$install_path"; then
        tlog_error "$tag" "Failed to create install directory: %s" "$install_path"

        return 3
    fi

    if ! tar --overwrite -xzf "$archive_file" -C "$install_path" --strip-components=1; then
        tlog_error "$tag" "Failed to extract Apache Maven into: %s" "$install_path"

        return 4
    fi

    if [[ ! -x "$install_path/bin/mvn" ]]; then
        tlog_error "$tag" "Maven executable was not installed: %s" "$install_path/bin/mvn"

        return 5
    fi

    add_to_path "$canonical_id" "$install_path/bin" || return 6
    set_registry "INSTALL_PATH" "$install_path" || return 7
    save_registry "$canonical_id" || return 7

    if ! command -v java >/dev/null 2>&1; then
        message="Java was not found. Install it with SDKMAN!: 'mp install dev/sdkman'"
        tlog_warn "$tag" "%s" "$message"
        if ! add_message "$canonical_id" warn "$message"; then
            tlog_warn "$tag" "Failed to persist the missing-Java warning"
        fi
    fi

    tlog_info "$tag" "Installation completed successfully"
}

main "$CANONICAL_ID" "${APACHE_MAVEN_INSTALL_DIR:-$INSTALL_DIR/apache-maven}"
