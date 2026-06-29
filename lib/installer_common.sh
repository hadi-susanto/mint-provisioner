#!/usr/bin/env bash

#
# Installer common functions
#

source "${LIB_DIR}/common.sh"

#
# __add_shell_source <module> <shell_name> <rc_file> <source_file> <caller_func>
#
# Adds a source line to the shell's RC file if it doesn't already exist.
# This function is considered private and should not be called directly.
#
__add_shell_source() {
    local module=$1
    local shell_name=$2
    local rc_file=$3
    local source_file=$4
    local caller_func=$5

    if ! command -v "$shell_name" >/dev/null 2>&1; then
        log_warn "[$caller_func] [$module] $shell_name is not available, skipping configuration"

        return 0
    fi

    log_info "[$caller_func] [$module] Configuring $module for $shell_name"
    log_info "[$caller_func] [$module] Source file: $source_file"

    if [[ ! -f "$rc_file" ]]; then
        log_info "[$caller_func] [$module] Creating $rc_file"
        if is_admin; then
            local target_user="${SUDO_USER:-$USER}"
            sudo -u "$target_user" touch "$rc_file"
        else
            touch "$rc_file"
        fi
    fi

    local source_line="[[ -f \"$source_file\" ]] && source \"$source_file\""

    if grep -Fq "$source_line" "$rc_file"; then
        log_warn "[$caller_func] [$module] $source_file source already exists in $rc_file"

        return 0
    fi

    log_info "[$caller_func] [$module] Adding $source_file source to $rc_file"
    if is_admin; then
        local target_user="${SUDO_USER:-$USER}"
        echo "$source_line" | sudo -u "$target_user" tee -a "$rc_file" > /dev/null
    else
        echo "$source_line" >> "$rc_file"
    fi
}

#
# add_bash_source <module> <source_file>
#
add_bash_source() {
    local module=$1
    local source_file=$2
    local user_home
    user_home=$(get_user_home)

    __add_shell_source "$module" "bash" "${user_home}/.bashrc" "$source_file" "add_bash_source"
}

#
# add_zsh_source <module> <source_file>
#
add_zsh_source() {
    local module=$1
    local source_file=$2
    local user_home
    user_home=$(get_user_home)

    __add_shell_source "$module" "zsh" "${user_home}/.zshrc" "$source_file" "add_zsh_source"
}
