#!/usr/bin/env bash

#
# Installer common functions
#

source "${LIB_DIR}/common.sh"

#
# Get the configuration directory for the current user
#
get_config_dir() {
    local user_home
    user_home=$(get_user_home)

    echo "${user_home}/.config/mint-provisioner"
}

#
# Copy a file to the configuration directory
# Arguments:
#   1. module: Module name
#   2. source: Source file path
#   3. force_var: Name of the environment variable for force configuration (e.g., GIT_FORCE_CONFIGURATION)
#
copy_to_config_dir() {
    local module="$1"
    local source="$2"
    local force_var="$3"
    local config_dir
    local filename
    local target
    local force_val="${!force_var}"

    if [[ ! -f "$source" ]]; then
        log_error "[copy_config] [$module] Source file $source does not exist"

        return 1
    fi

    config_dir=$(get_config_dir)
    filename=$(basename "$source")
    target="${config_dir}/${filename}"

    if [[ ! -d "$config_dir" ]]; then
        mkdir -p "$config_dir"
    fi

    if [[ ! -f "$target" ]]; then
        log_info "[copy_config] [$module] copying $source to $target"
        cp "$source" "$target"

        return 0
    fi

    if [[ "$force_val" == "true" ]]; then
        log_warn "[copy_config] [$module] $target already exists, overwrite file because $force_var is true"
        log_info "[copy_config] [$module] copying $source to $target"
        cp "$source" "$target"

        return 0
    fi

    log_warn "[copy_config] [$module] $target already exists, to overwrite existing file please set $force_var to true"
}

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
        touch "$rc_file"
    fi

    local source_line="[[ -f \"$source_file\" ]] && source \"$source_file\""

    if grep -Fq "$source_line" "$rc_file"; then
        log_warn "[$caller_func] [$module] $source_file source already exists in $rc_file"

        return 0
    fi

    log_info "[$caller_func] [$module] Adding $source_file source to $rc_file"
    echo "$source_line" >> "$rc_file"
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
