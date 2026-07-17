#!/usr/bin/env bash

#
# Installer common functions
#

source "${LIB_DIR}/common.sh"
source "${LIB_DIR}/messages.sh"

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

    config_dir="$(get_config_dir)"
    filename="${source##*/}"
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

    if [[ ! -f "$source_file" ]]; then
        log_error "[$caller_func] [$module] $source_file is not available/not a file, unable to configure $shell_name integration"

        return 1
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

#
# Get the location where symbolic links for binaries are created
#
symlink_location() {
    echo "/usr/local/bin"
}

#
# Create a symbolic link for a binary in /usr/local/bin
# Arguments:
#   1. module: Module name
#   2. source_binary: Path to the source binary
#
symlink_binary() {
    local module="$1"
    local source_binary="$2"
    local dest_dir
    dest_dir=$(symlink_location)

    if [[ ! -f "$source_binary" ]]; then
        log_error "[symlink_binary] [$module] Source file $source_binary does not exist"

        return 1
    fi

    if [[ ! -x "$source_binary" ]]; then
        log_error "[symlink_binary] [$module] Source file $source_binary is not executable"

        return 1
    fi

    log_info "[symlink_binary] [$module] Creating symbolic link for $source_binary in $dest_dir"
    sudo ln -sf "$source_binary" "${dest_dir}/"
}

#
# Add a directory to the PATH environment variable
# Arguments:
#   1. module: Module name
#   2. source_path: Path to the directory to add to PATH
#
add_to_path() {
    local module="$1"
    local source_path="$2"

    if [[ ! -d "$source_path" ]]; then
        log_error "[add_to_path] [$module] Source path $source_path is not a directory"

        return 1
    fi

    # Check if directory is empty
    if [[ -z "$(ls -A "$source_path")" ]]; then
        log_error "[add_to_path] [$module] Source path $source_path is empty"

        return 1
    fi

    local profile_script="/etc/profile.d/99-path-${module}.sh"
    log_info "[add_to_path] [$module] Registering $source_path to $profile_script"

    local content
    content=$(cat <<EOF
case ":\$PATH:" in
  *":${source_path}:"*) ;;
  *) export PATH="${source_path}:\$PATH" ;;
esac
EOF
)

    echo "$content" | sudo tee "$profile_script" > /dev/null

    log_warn "[$module] PATH has been updated. You may need to log out and log back in for the changes to take effect."
    add_message "$module" "info" "New directory added to PATH: $source_path. Please relogin to apply changes."
}
