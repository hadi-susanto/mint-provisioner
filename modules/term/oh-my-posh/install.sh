#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/extractor.sh"
source "$LIB_INSTALLER/messages.sh"
source "$LIB_INSTALLER/path.sh"
source "$LIB_INSTALLER/registry.sh"
source "$LIB_INSTALLER/state.sh"
source "$LIB_INSTALLER/symlink.sh"

__install_binary() {
    local canonical_id="$1"
    local install_path="$2"
    local tag="install:$canonical_id"
    local binary_file

    tlog_info "$tag" "Installing Oh My Posh binary to: %s" "$install_path"
    binary_file="$(get_state "BINARY_FILE")" || return $?
    if [[ ! -f "$binary_file" ]]; then
        tlog_error "$tag" "Oh My Posh binary not found: %s" "$binary_file"

        return 1
    fi
    if ! mkdir -p "$install_path"; then
        tlog_error "$tag" "Failed to create install directory: %s" "$install_path"

        return 1
    fi
    if ! cp "$binary_file" "$install_path/oh-my-posh"; then
        tlog_error "$tag" "Failed to copy %s to %s" "$binary_file" "$install_path/oh-my-posh"

        return 1
    fi
    if ! chmod +x "$install_path/oh-my-posh"; then
        tlog_error "$tag" "Failed to make %s executable" "$install_path/oh-my-posh"

        return 1
    fi

    symlink_binary "$canonical_id" "$install_path/oh-my-posh"
}

__install_themes() {
    local canonical_id="$1"
    local install_path="$2"
    local tag="install:$canonical_id"
    local archive_file

    tlog_info "$tag" "Installing Oh My Posh themes to: %s" "$install_path"
    archive_file="$(get_state "THEMES_FILE")" || return $?
    extract_archive "$canonical_id" "zip" "$archive_file" "$install_path"
}

load_states "$CANONICAL_ID" || exit 1
install_path="$(expand_path "${OH_MY_POSH_INSTALL_DIR:-$INSTALL_DIR/oh-my-posh}")" || exit $?
__install_binary "$CANONICAL_ID" "$install_path" || exit $?
__install_themes "$CANONICAL_ID" "$install_path/themes" || exit $?

set_registry "INSTALL_PATH" "$install_path" || exit $?
save_registry "$CANONICAL_ID" || exit $?

msg="Oh My Posh requires a Nerd Font to be installed. Ensure you
have a Nerd Font installed.
To install one, you can use mint-provisioner."

add_message "$CANONICAL_ID" "info" "$msg"

msg="Unless System Toolkit is used to enable the shell
integration, configure Oh My Posh manually:
  https://ohmyposh.dev/docs/installation/prompt"

add_message "$CANONICAL_ID" "info" "$msg"
add_system_toolkit_message "$CANONICAL_ID"
